terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  backend "azurerm" {
      resource_group_name  = "MKSRG01"
      storage_account_name = "mksterrastore01"
      container_name       = "terracontr01"
      key                  = "mks2.tfstate"
  }

}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "MKS-ResGroup01"
  location = "westus"
}

resource "azurerm_virtual_network" "example" {
  name                = "MKS-Network"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "internal" {
  count                = 2
  name                 = "subnet-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.10.${count.index}.0/24"]
}

resource "azurerm_public_ip" "example" {
  count                = 2
  name                 = "MKS-public-ip-${count.index}"
  location             = azurerm_resource_group.example.location
  resource_group_name  = azurerm_resource_group.example.name
  allocation_method    = "Dynamic"
}

resource "azurerm_network_interface" "example" {
  count               = 2
  name                = "MKS-nic-${count.index}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal[count.index % 2].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example[count.index].id
  }
}

resource "azurerm_windows_virtual_machine" "example" {
  count               = 2
  name                = "MKS-machine-${count.index}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  network_interface_ids = [azurerm_network_interface.example[count.index].id]
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

}