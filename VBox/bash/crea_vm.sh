#!/bin/bash

# Ari (Administrador de xarxes)
# Generic VirtualBox VM creation script with configuration file support

# Display usage instructions
usage() {
    echo "Usage: $0 <configuration_file>"
    echo ""
    echo "Example:"
    echo "  $0 config/r00.conf"
    echo ""
    echo "The configuration file must define the following required variables:"
    echo "  - VM_NAME: Name of the virtual machine"
    echo "  - VM_OSTYPE: Operating system type (e.g., Debian_64)"
    echo "  - VM_MEMORY: Memory size in MB"
    echo "  - VM_DISK_SIZE: Disk size in MB"
    echo "  - VM_INTNET: Internal network name"
    echo ""
    echo "Optional variables (with defaults):"
    echo "  - SSH_HOST_PORT (default: 2222)"
    echo "  - SSH_GUEST_PORT (default: 22)"
    echo "  - BOOT_DEVICE (default: dvd)"
    echo "  - VM_VRAM (default: 16)"
    echo "  - VM_GRAPHICS (default: vmsvga)"
    exit 1
}

# Check if configuration file is provided
if [ $# -ne 1 ]; then
    echo "Error: Configuration file not provided."
    usage
fi

CONFIG_FILE="$1"

# Verify configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found."
    exit 1
fi

# Source the configuration file
# Note: Only source configuration files from trusted sources.
# The configuration file should contain only variable assignments.
echo "Loading configuration from: $CONFIG_FILE"
# shellcheck source=/dev/null
source "$CONFIG_FILE"

# Validate required variables
REQUIRED_VARS=("VM_NAME" "VM_OSTYPE" "VM_MEMORY" "VM_DISK_SIZE" "VM_INTNET")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required variable '$var' is not defined in the configuration file."
        exit 1
    fi
done

# Set defaults for optional variables
SSH_HOST_PORT="${SSH_HOST_PORT:-2222}"
SSH_GUEST_PORT="${SSH_GUEST_PORT:-22}"
BOOT_DEVICE="${BOOT_DEVICE:-dvd}"
VM_VRAM="${VM_VRAM:-16}"
VM_GRAPHICS="${VM_GRAPHICS:-vmsvga}"

# Define additional variables
HOME_DIR="$HOME"
VM_DIR="$HOME_DIR/VirtualBox VMs/$VM_NAME"

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
echo "Configuring resources (Memòria: ${VM_MEMORY}MB, VRAM: ${VM_VRAM}MB, Gràfica: ${VM_GRAPHICS})..."
VBoxManage modifyvm "$VM_NAME" --memory "$VM_MEMORY" --vram "$VM_VRAM" --acpi "on" --boot1 "$BOOT_DEVICE" --graphicscontroller "$VM_GRAPHICS" --bioslogoimagepath "$VM_BIOS_LOGO"
check_error

# 4. Configurar xarxa (NIC 1: NAT, NIC 2: internal network)
echo "Configurant interfícies de xarxa..."
VBoxManage modifyvm "$VM_NAME" --nic1 "nat"
check_error
VBoxManage modifyvm "$VM_NAME" --nic2 "intnet" --intnet2 "$VM_INTNET"
check_error

# 5. Port Forwarding (SSH)
echo "Configurant port forwarding (${SSH_HOST_PORT} -> ${SSH_GUEST_PORT})..."
VBoxManage modifyvm "$VM_NAME" --natpf1 "SSH,tcp,,${SSH_HOST_PORT},,${SSH_GUEST_PORT}"
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
