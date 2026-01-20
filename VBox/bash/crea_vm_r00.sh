#!/bin/bash

# Ari (Administrador de xarxes)
# Versió Bash de la creació de la màquina virtual del router r00

# Variables
VM_NAME="r00"
VM_OSTYPE="Debian_64"
VM_MEMORY=2048
VM_DISK_SIZE=1048576 # 1 TB (1024 * 1024 MB)
HOME_DIR="$HOME"
VM_DIR="$HOME_DIR/VirtualBox VMs/$VM_NAME"
VM_INTNET="x00"

# Determine script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ruta a la ISO (ajustar si és necessari)
VM_ISO_FILE="$SCRIPT_DIR/../ISO/debian.iso"
VM_ICON="$SCRIPT_DIR/../icons/debian.svg"
VM_BIOS_LOGO="$SCRIPT_DIR/../icons/cdm.bmp"

# Funció per gestionar errors
check_error() {
    if [ $? -ne 0 ]; then
        echo "Error executant el darrer comandament."
        exit 1
    fi
}

echo "Iniciant la creació de la màquina virtual $VM_NAME..."

# 1. Comprovar si la VM ja existeix
if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
    echo "Error: La màquina virtual $VM_NAME ja existeix."
    exit 1
fi

# 2. Crear la màquina virtual
echo "Creant la VM $VM_NAME..."
VBoxManage createvm --name "$VM_NAME" --ostype "$VM_OSTYPE" --register
check_error

# 2.1 Configurar la icona
if [ -f "$VM_ICON" ]; then
    echo "Configurant la icona de la VM $VM_NAME..."
    VBoxManage modifyvm "$VM_NAME" --icon-file "$VM_ICON"
    check_error
else
    echo "Avís: No s'ha trobat la icona a $VM_ICON"
fi

# 3. Configurar memòria, CPU i ports
echo "Configuring resources (Memòria: ${VM_MEMORY}MB, VRAM: 16MB, Gràfica: VMSVGA)..."
VBoxManage modifyvm "$VM_NAME" --memory "$VM_MEMORY" --vram "16" --acpi "on" --boot1 "dvd" --graphicscontroller "vmsvga" --bioslogoimagepath "$VM_BIOS_LOGO"
check_error

# 4. Configurar xarxa (NIC 1: NAT, NIC 2: x00)
echo "Configurant interfícies de xarxa..."
VBoxManage modifyvm "$VM_NAME" --nic1 "nat"
check_error
VBoxManage modifyvm "$VM_NAME" --nic2 "intnet" --intnet2 "$VM_INTNET"
check_error

# 5. Port Forwarding (SSH: 2222 -> 22)
echo "Configurant port forwarding (2222 -> 22)..."
VBoxManage modifyvm "$VM_NAME" --natpf1 "SSH,tcp,,2222,,22"
check_error

# 6. Crear i adjuntar disc dur
echo "Creant disc virtual de ${VM_DISK_SIZE}MB..."
mkdir -p "$VM_DIR"
HD_PATH="$VM_DIR/$VM_NAME.vdi"
VBoxManage createhd --filename "$HD_PATH" --size "$VM_DISK_SIZE"
check_error

echo "Configurant controladors d'emmagatzematge..."
VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add "sata" --controller "IntelAhci"
check_error
VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port "0" --device "0" --type "hdd" --medium "$HD_PATH"
check_error

# 7. Adjuntar ISO (si existeix)
VBoxManage storagectl "$VM_NAME" --name "IDE Controller" --add "ide"
check_error
if [ -f "$VM_ISO_FILE" ]; then
    echo "Adjuntant ISO: $VM_ISO_FILE"
    VBoxManage storageattach "$VM_NAME" --storagectl "IDE Controller" --port "0" --device "0" --type "dvddrive" --medium "$VM_ISO_FILE"
    check_error
else
    echo "Avís: No s'ha trobat el fitxer ISO a $VM_ISO_FILE. S'ha creat la VM sense ISO."
fi

echo "Màquina virtual $VM_NAME creada correctament."
