# terraform-ajc

Infrastructure réseau AWS de bout en bout (VPC, sous-réseau public/privé, bastion SSH) déployée avec Terraform, découpée en modules réutilisables.

## Architecture

Un VPC contenant deux sous-réseaux dans la même zone de disponibilité : un sous-réseau public qui héberge une instance bastion et la passerelle NAT, et un sous-réseau privé qui héberge une instance applicative sans adresse publique. La sortie internet du sous-réseau privé passe exclusivement par la passerelle NAT ; l'entrée SSH ne se fait que par rebond via le bastion.

```
Poste de travail
      │ SSH (ProxyJump)
      ▼
┌─────────────────────────────┐
│ VPC 10.0.0.0/16              │
│                               │
│  Sous-réseau public 10.0.1.0/24
│  ┌─────────┐   ┌─────┐       │
│  │ bastion │   │ NAT │──────▶│──▶ Internet (IGW)
│  └────┬────┘   └─────┘       │
│       │ SSH                  │
│       ▼                      │
│  Sous-réseau privé 10.0.11.0/24
│  ┌─────────┐                 │
│  │   app   │                 │
│  └─────────┘                 │
└─────────────────────────────┘
```

## Structure du projet

```
terraform-ajc/
├── provider.tf              # bloc terraform{} et provider aws
├── variables.tf              # variables globales (région, CIDR, poste_nn...)
├── main.tf                   # assemblage des trois modules
├── outputs.tf                 # IP et commande SSH finales
├── terraform.tfvars.example  # modèle à copier en terraform.tfvars
├── .gitignore
└── modules/
    ├── vpc/                   # VPC, sous-réseaux, IGW, NAT, tables de routage
    ├── security/               # groupes de sécurité bastion et privé
    └── ec2/                    # clé SSH, instances, config SSH locale
```

Chaque module est autonome et ne connaît que ses propres variables d'entrée ; c'est `main.tf` à la racine qui relie leurs sorties entre eux (`module.vpc.vpc_id` → `security`, `module.vpc.*` et `module.security.*` → `ec2`).

## Prérequis

- Terraform >= 1.5
- Un accès AWS valide (clés d'accès classiques ou session SSO), avec les droits sur VPC, EC2, EIP et security groups
- Un client SSH supportant `ProxyJump` (OpenSSH >= 7.3)

## Configuration des credentials AWS

```bash
aws configure
```
ou, pour un compte SSO :
```bash
aws sso login --profile <nom-du-profil>
export AWS_PROFILE=<nom-du-profil>
```

## Utilisation

```bash
cp terraform.tfvars.example terraform.tfvars
```
Éditez `terraform.tfvars` avec votre numéro de poste et votre IP publique (`curl -s https://checkip.amazonaws.com`) :
```hcl
poste_nn   = "17"
ma_cidr_ip = "VOTRE_IP_PUBLIQUE/32"
```

```bash
terraform init
terraform plan
terraform apply
```

À la fin de l'`apply`, l'output `commande_ssh_par_rebond` donne la commande exacte pour joindre l'instance privée :
```bash
ssh -F ./ssh_config_tp-<poste_nn> tp-<poste_nn>-app
```

## Variables principales

| Variable | Description | Défaut |
|---|---|---|
| `region` | Région AWS | `eu-west-2` |
| `poste_nn` | Numéro de poste, préfixe de toutes les ressources | `17` |
| `ma_cidr_ip` | IP publique autorisée en SSH sur le bastion, format `/32` | (obligatoire) |
| `vpc_cidr` | Plage du VPC | `10.0.0.0/16` |
| `availability_zone` | Zone de disponibilité des deux sous-réseaux | `eu-west-2a` |
| `test_panne_sg` | Retire la règle entrante du SG privé (test de panne) | `false` |
| `test_panne_route` | Retire la route par défaut de la table privée (test de panne) | `false` |

## Tests de panne

```bash
terraform apply -var="test_panne_sg=true"      # coupe SSH bastion → app
terraform apply -var="test_panne_sg=false"     # remet la règle
terraform apply -var="test_panne_route=true"   # coupe la sortie internet privée
terraform apply -var="test_panne_route=false"  # remet la route
```

## Nettoyage

```bash
terraform destroy
```
L'ordre de suppression (instances, NAT, EIP, IGW, tables, sous-réseaux, VPC) est géré automatiquement par le graphe de dépendances Terraform.

## Sécurité

- La clé privée (`tp-<poste_nn>-cle.pem`) est générée par Terraform et écrite uniquement en local, jamais copiée sur le bastion.
- `terraform.tfvars`, `*.tfstate`, `*.pem` et le fichier de config SSH généré sont exclus du dépôt via `.gitignore`.
- Aucune règle de sécurité n'ouvre le port SSH à `0.0.0.0/0` : le bastion n'autorise que `ma_cidr_ip`, l'instance privée n'autorise que le security group du bastion.

## Problèmes connus

- **`NatGatewayLimitExceeded`** : le quota de 5 NAT Gateways par région est atteint. Vérifiez les NAT Gateways existantes (`aws ec2 describe-nat-gateways`) et nettoyez celles qui vous appartiennent, ou changez de région.
- **`No valid credential sources found`** : configurez `aws configure` ou exportez `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_DEFAULT_REGION` avant `terraform plan`.