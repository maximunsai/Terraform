terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.19.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rsg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  resource_group_name = azurerm_resource_group.rsg.name
  location            = azurerm_resource_group.rsg.location
  address_space       = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.rsg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/28"]
}

resource "azurerm_public_ip" "publicIP" {
  name                = "publicIP"
  resource_group_name = azurerm_resource_group.rsg.name
  location            = azurerm_resource_group.rsg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic"
  resource_group_name = azurerm_resource_group.rsg.name
  location            = azurerm_resource_group.rsg.location
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicIP.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.rsg.location
  resource_group_name = azurerm_resource_group.rsg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_virtual_machine" "tfvm" {
  name                  = "tfvm"
  resource_group_name   = azurerm_resource_group.rsg.name
  location              = azurerm_resource_group.rsg.location
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_B1s"

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  os_profile {
    computer_name  = "tfvm"
    admin_username = "xxxx"
    admin_password = "xxxx"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }


  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "xxxx"
      password = "xxxx"
      host     = azurerm_public_ip.publicIP.ip_address
    }

    inline = [
      "sudo apt update -y",
      "sudo apt install -y openjdk-17-jdk",
      "java -version"
    ]
  }

  tags = {
    environment = var.tags.Environment
  }
}

