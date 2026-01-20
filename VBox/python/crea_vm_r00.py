#!/usr/bin/env python3
import subprocess
import os
import sys

# Ari (Administrador de xarxes)
# Versió Python de la creació de la màquina virtual del router r00

# Variables
VM_NAME = "r00"
VM_OSTYPE = "Debian_64"
VM_MEMORY = 2048
VM_DISK_SIZE = 1048576 # 1 TB (1024 * 1024 MB)
HOME_DIR = os.path.expanduser('~')
VM_DIR = os.path.join(HOME_DIR, "VirtualBox VMs", VM_NAME)
VM_INTNET = "x00"

# Determine script directory for relative paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Ruta a la ISO (ajustar si és necessari)
VM_ISO_FILE = os.path.join(SCRIPT_DIR, "../ISO/debian.iso")
VM_ICON = os.path.join(SCRIPT_DIR, "../icons/debian.svg")
VM_BIOS_LOGO = os.path.join(SCRIPT_DIR, "../icons/cdm.bmp")

def run_command(command, check=True):
    """Executa un comando de la shell i retorna el resultat."""
    try:
        result = subprocess.run(command, check=check, capture_output=True, text=True)
        return result
    except subprocess.CalledProcessError as e:
        if check:
            print(f"Error executant el comando: {' '.join(command)}")
            print(f"Sortida d'error: {e.stderr}")
            sys.exit(1)
        return e

def main():
    print(f"Iniciant la creació de la màquina virtual {VM_NAME}...")

    # 1. Comprovar si la VM ja existeix
    list_vms = run_command(["VBoxManage", "list", "vms"])
    if f'"{VM_NAME}"' in list_vms.stdout:
        print(f"Error: La màquina virtual {VM_NAME} ja existeix.")
        sys.exit(1)

    # 2. Crear la màquina virtual
    print(f"Creant la VM {VM_NAME}...")
    run_command(["VBoxManage", "createvm", "--name", VM_NAME, "--ostype", VM_OSTYPE, "--register"])

    # 2.1 Configurar la icona
    if os.path.exists(VM_ICON):
        print(f"Configurant la icona de la VM {VM_NAME}...")
        run_command(["VBoxManage", "modifyvm", VM_NAME, "--icon-file", VM_ICON])
    else:
        print(f"Avís: No s'ha trobat la icona a {VM_ICON}")

    # 3. Configurar memòria, CPU i ports
    print(f"Configuring resources (Memòria: {VM_MEMORY}MB, VRAM: 16MB, Gràfica: VMSVGA)...")
    run_command(["VBoxManage", "modifyvm", VM_NAME, "--memory", str(VM_MEMORY), "--vram", "16", "--acpi", "on", "--boot1", "dvd", "--graphicscontroller", "vmsvga", "--bioslogoimagepath", VM_BIOS_LOGO])

    # 4. Configurar xarxa (NIC 1: NAT, NIC 2: x00)
    print("Configurant interfícies de xarxa...")
    run_command(["VBoxManage", "modifyvm", VM_NAME, "--nic1", "nat"])
    run_command(["VBoxManage", "modifyvm", VM_NAME, "--nic2", "intnet", "--intnet2", VM_INTNET])

    # 5. Port Forwarding (SSH: 2222 -> 22)
    print("Configurant port forwarding (2222 -> 22)...")
    run_command(["VBoxManage", "modifyvm", VM_NAME, "--natpf1", "SSH,tcp,,2222,,22"])

    # 6. Crear i adjuntar disc dur
    print(f"Creant disc virtual de {VM_DISK_SIZE}MB...")
    os.makedirs(VM_DIR, exist_ok=True)
    hd_path = os.path.join(VM_DIR, f"{VM_NAME}.vdi")
    run_command(["VBoxManage", "createhd", "--filename", hd_path, "--size", str(VM_DISK_SIZE)])

    print("Configurant controladors d'emmagatzematge...")
    run_command(["VBoxManage", "storagectl", VM_NAME, "--name", "SATA Controller", "--add", "sata", "--controller", "IntelAhci"])
    run_command(["VBoxManage", "storageattach", VM_NAME, "--storagectl", "SATA Controller", "--port", "0", "--device", "0", "--type", "hdd", "--medium", hd_path])

    # 7. Adjuntar ISO (si existeix)
    run_command(["VBoxManage", "storagectl", VM_NAME, "--name", "IDE Controller", "--add", "ide"])
    if os.path.exists(VM_ISO_FILE):
        print(f"Adjuntant ISO: {VM_ISO_FILE}")
        run_command(["VBoxManage", "storageattach", VM_NAME, "--storagectl", "IDE Controller", "--port", "0", "--device", "0", "--type", "dvddrive", "--medium", VM_ISO_FILE])
    else:
        print(f"Avís: No s'ha trobat el fitxer ISO a {VM_ISO_FILE}. S'ha creat la VM sense ISO.")

    print(f"Màquina virtual {VM_NAME} creada correctament.")

if __name__ == "__main__":
    main()
