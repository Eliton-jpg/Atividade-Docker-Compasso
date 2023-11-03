# PRÁTICA DOCKER

A atividade consiste em:
 1. instalação e configuração do DOCKER ou CONTAINERD no host EC2; Ponto adicional para o trabalho utilizar a instalação via script de Start Instance (user_data.sh);
 2. Efetuar Deploy de uma aplicação Wordpress com: container de aplicação RDS database Mysql;
 3. Configuração da utilização do serviço EFS AWS para estáticos do container de aplicação Wordpress;
 4. Configuração do serviço de Load Balancer AWS para a aplicação Wordpress;
   


# AWS Configurações

Configurações da Infraestrutura

## Virtual Private Cloud (VPC)

A VPC esta dividida entre duas tabelas de rotas, em que uma é para as subnets privadas e a outra para as subnets públicas, temos duas subnets privadas e públicas, a criação das subnets privadas são para os containers docker com o wordpress, para que seja disponibilizado em um endereço ip privado. As subnets públicas são para permitir que o load balancer consiga conectar-se a internet a partir das duas AZs distintas que elas estão localizadas, para aumentar a disponibilidade, a rout table pública possuí um internet gateway para acessar a internet e a rout table privada possuí um NAT gateway para permitir o tráfego apenas de saída das subnets públicas.



## Security Group (Gurpos de Seguraça)

Para essa atividade foram criados dois grupos de segurança:

Security Group para EC2, Load Balancer:

|Tipo|Protocolo|Porta|Origem|
|----------|-----|-----|----|
|SSH|TCP|22|0.0.0.0/0|
|HTTP|TCP|80|0.0.0.0/0|
|HTTPS|TCP|443|0.0.0.0/0|


Security Group para RDS:

|Tipo|Protocolo|Porta|Origem|
|----------|-----|-----|----|
|MYSQL/Aurora|TCP|3306|SG_EC2|
|MYSQL/Aurora|TCP|3306|MEU_IP|

Security Group para EFS:

|Tipo|Protocolo|Porta|Origem|
|----------|-----|-----|----|
|NFS|TCP|2049|0.0.0.0/0|

## Autoscaling (escalonamento automático)

Para a configuração do autoscaling, foi criado o launcher template que utiliza o user_data.sh.

A configuração do autoscaling segue essas etapas:
 1. Ir para a seção de "Grupos do Auto Scaling e "criar grupo do Auto Scaling";
 2. Selecionar o launcher template criado;
 3. Escolher a VPC;
 4. Selecionar as subnets privadas;
 5. Em balanceador de carga, pode-se selecionar o já criado, ou criar posteriormente;
 6. Selecionar a capacidade desejada, mínima e máxima como 2(que foi requerido na atividade);
  
### Launcher Templete(Templete de execução)

Para o modelo de execução, foi escolhida uma máquina igual a atividade anterior:
 1. Amzon Linux 2;
 2. t3 small;
 3. 16 Gb de volume;
 4. Tags de criação;
 5. User_data.sh 

## Load Balancer (Balanceador de Carga)

A criação do load balancer, segue as seguintes etapas: 
 1. Ir para a seção de load balancers na AWS, criar lod balancer;
 2. Tipo de "Application Load Balancer";
 3. Esquema de "Internet-Facing", tipo de IP como "IPv4";
 4. Mapear as subnets públicas de cada AZ;
 5. Associar um grupo de segurança com o LoadBalancer;
 6. Nos listerners e roteamento, selecionar o target group criado;

### TARGET GROUP(Gurpo de Destino)

Para configurar o target group, devesse seguir as seguintes etapas: 
 1. Ir para a seção de grupos de destino na AWS, criar grupo de destino;
 2. Na configuração básica selecionar instâncias;
 3. Selecionar o protocolo e a porta "HTTP" e "80" "respectivamente, tipo de endereçamento IP será o "IPv4";
 4. Associar a VPC que estarão as instâncias EC2;
 5. Escolher o caminho para verificação de integridade que serão  "/" e "HTTP";
 6. Depois basta registrar as instâncias;

## Relational Database Service (RDS)

O RDS foi configurado seguindo as etapas:
 1. Ir para a seção e RDS e Criar banco de dados;
 2. Selecionar Método de criação padrão juntamente com MySQL;
 3. Selecionar o free tier;
 4. Inserir o nome de indentificador da instância;
 5. Configurar nome e senha do usuário;
 6. Configuração de instância foi "db.t3.micro";
 7. Armazenamento gp2;
 8. Conectividade opção "não se conectar a um recurso de computação do EC2";
 9. IPv4;
 10. Selecionar a VPC da atividade;
 11. Criar security group para o RDS;
 12. Zona de disponibilidade como "Sem preferência";
 13. Atuoridade de certificação como padrão;
 14. Autenticação com senha;
 15. Ir em configurações adicionais e colocar o nome do RDS(não confudir com identificador da instância);



## Elastic File System (EFS)

Para criar o Elastic File System, basta:

 1. Ir para a seção e EFS na AWS;
 2. Clicar em "Criar sistema de arquivos";
 3. Digitar o nome para o EFS ;
 4. Selecionar  VPC que ele ficará;

# SCRIPT E ARQUIVO DE IMAGEM .YAML

 Foi criado um arquivo .yaml no meu github pessoal e depois chamo esse arquivo no user_data.sh que ficará no laucher templete de cada uma das máquinas que será iniciada no autoscaling group.

user_data.sh:(tive problemas com o script e tive que colocar sudo na frente de cada comando para executar)

```sh
#!/bin/bash
sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# Dar permissões de execução 
sudo chmod +x /usr/local/bin/docker-compose
# curl no arquivo .yaml do meu git-hub e criar um arquivoc om  mesmo nome e conteúdo
sudo curl -sL "https://raw.githubusercontent.com/Eliton-jpg/Atividade-Docker-Compasso/main/docker-compose.yaml" --output "/home/ec2-user/docker-compose.yaml" 

# Instalação e configuração do EFS 
sudo yum install amazon-efs-utils -y
sudo systemctl enable nfs-utils.service
sudo systemctl start nfs-utils.service
# permissões ao diretório leitura, escrita e execução 
sudo chmod +rwx /mnt/efs/
# sistema de arquivos com o EFS
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-07c68e847f4ea9744.efs.us-east-1.amazonaws.com:/ /mnt/efs/
echo "fs-07c68e847f4ea9744.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs defaults 0 0" >> /etc/fstab
# Execução do docker-compose
docker-compose -f /home/ec2-user/docker-compose.yaml up -d
```

```yaml
version: '3.7'
services:
  wordpress:
    image: wordpress
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: ENDPOIT_RDS
      WORDPRESS_DB_USER: USER_RDS
      WORDPRESS_DB_PASSWORD: SENHA_RDS
      WORDPRESS_DB_NAME: NAME_RDS
    volumes:
      - /mnt/efs/wordpress:/var/www/html
```


