#!/bin/bash

# Unified pigpio installer with menu options
# Supports both local and remote installation

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display menu
show_menu() {
    clear
    echo -e "${CYAN}=========================================="
    echo -e "         pigpio Installer Menu"
    echo -e "==========================================${NC}"
    echo ""
    echo -e "${YELLOW}Choose installation option:${NC}"
    echo ""
    echo -e "${GREEN}1${NC}) Install pigpio locally (current system)"
    echo -e "${GREEN}2${NC}) Install pigpio on remote Raspberry Pi"
    echo -e "${GREEN}3${NC}) Exit"
    echo ""
    echo -e "${BLUE}=========================================="
    echo -n -e "${YELLOW}Enter your choice [1-3]: ${NC}"
}

# Function for local installation
install_local() {
    echo -e "${BLUE}=========================================="
    echo -e "Starting LOCAL pigpio installation"
    echo -e "==========================================${NC}"
    
    # Check if running on Raspberry Pi
    if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null && ! grep -q "BCM" /proc/cpuinfo 2>/dev/null; then
        echo -e "${YELLOW}Warning: This doesn't appear to be a Raspberry Pi.${NC}"
        echo -e "${YELLOW}pigpio is designed for Raspberry Pi GPIO control.${NC}"
        echo -n "Continue anyway? [y/N]: "
        read -r continue_install
        if [[ ! "$continue_install" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            return 1
        fi
    fi
    
    set -e  # Exit on any error

    # Step 0: Install dependencies
    echo ""
    echo -e "${BLUE}Step 0: Installing dependencies...${NC}"
    sudo apt update
    sudo apt install -y git build-essential cmake pkg-config
    echo -e "${GREEN}✓ Dependencies installed${NC}"

    # Step 1: Clone the pigpio repository
    echo ""
    echo -e "${BLUE}Step 1: Preparing and cloning pigpio repository...${NC}"
    echo "Cleaning up any existing pigpio directory..."
    if [ -d "pigpio" ]; then
        echo "pigpio directory exists. Removing it first..."
        sudo rm -rf pigpio
    else
        echo "No existing pigpio directory found."
    fi

    echo "Cloning fresh pigpio repository..."
    git clone https://github.com/joan2937/pigpio.git
    echo -e "${GREEN}✓ Repository cloned successfully${NC}"

    # Step 2: Build and install from source
    echo ""
    echo -e "${BLUE}Step 2: Building and installing pigpio from source...${NC}"
    cd pigpio
    echo "Running make..."
    make
    echo "Running sudo make install..."
    sudo make install
    cd ..
    echo -e "${GREEN}✓ pigpio built and installed from source${NC}"

    # Step 3: Install additional packages
    echo ""
    echo -e "${BLUE}Step 3: Installing additional pigpio packages...${NC}"
    sudo apt update

    echo "Installing libpigpiod-if-dev (development headers)..."
    sudo apt install -y libpigpiod-if-dev

    echo "Checking for libpigpiod-if2 variants..."
    if apt list libpigpiod-if2-1t64 2>/dev/null | grep -q libpigpiod-if2-1t64; then
        echo "Installing libpigpiod-if2-1t64 (client library interface)..."
        sudo apt install -y libpigpiod-if2-1t64
    elif apt list libpigpiod-if2 2>/dev/null | grep -q libpigpiod-if2; then
        echo "Installing libpigpiod-if2 (client library interface)..."
        sudo apt install -y libpigpiod-if2
    else
        echo "⚠ libpigpiod-if2 package not found, skipping (already built from source)"
    fi

    echo "Installing pigpio-tools (command-line tools)..."
    sudo apt install -y pigpio-tools

    echo "Installing python3-pigpio (Python binding)..."
    sudo apt install -y python3-pigpio

    echo -e "${GREEN}✓ Available packages installed${NC}"

    # Step 4: Enable and start the daemon
    echo ""
    echo -e "${BLUE}Step 4: Enabling and starting pigpiod daemon...${NC}"
    sudo systemctl enable pigpiod
    echo -e "${GREEN}✓ pigpiod enabled to start on boot${NC}"
    sudo systemctl start pigpiod
    echo -e "${GREEN}✓ pigpiod daemon started${NC}"

    # Step 5: Test if running
    echo ""
    echo -e "${BLUE}Step 5: Testing pigpiod status...${NC}"
    echo "=========================================="
    sudo systemctl status pigpiod --no-pager
    echo "=========================================="

    # Additional verification
    echo ""
    echo -e "${BLUE}Additional verification:${NC}"
    if pgrep -x "pigpiod" > /dev/null; then
        echo -e "${GREEN}✓ pigpiod process is running${NC}"
    else
        echo -e "${RED}⚠ pigpiod process not found${NC}"
    fi

    # Check if pigpiod is listening on default port
    if ss -ltn | grep -q ":8888"; then
        echo -e "${GREEN}✓ pigpiod is listening on port 8888${NC}"
    else
        echo -e "${RED}⚠ pigpiod not listening on port 8888${NC}"
    fi

    echo ""
    echo -e "${GREEN}=========================================="
    echo -e "LOCAL pigpio installation completed!"
    echo -e "==========================================${NC}"
    echo ""
    echo "You can now use:"
    echo "- Command line tools like 'pigs' for GPIO control"
    echo "- Python library: import pigpio"
    echo "- C library: link with -lpigpio"
    echo ""
    echo "For remote access, pigpiod runs on port 8888 by default"
    echo ""
    echo -e "${YELLOW}Quick test commands:${NC}"
    echo -e "${CYAN}Try: pigs t 17${NC}"
    echo -e "${CYAN}…to toggle GPIO 17 on/off${NC}"
}

# Function for remote installation
install_remote() {
    echo -e "${BLUE}=========================================="
    echo -e "Starting REMOTE pigpio installation"
    echo -e "==========================================${NC}"
    
    # Get remote connection details
    echo -e "${YELLOW}Remote Raspberry Pi connection details:${NC}"
    echo -n "Enter Raspberry Pi IP address: "
    read -r RPI_IP
    
    echo -n "Enter username [pi]: "
    read -r RPI_USER
    RPI_USER=${RPI_USER:-pi}
    
    echo -n "Enter SSH port [22]: "
    read -r RPI_PORT
    RPI_PORT=${RPI_PORT:-22}
    
    echo ""
    echo -e "${YELLOW}Target: ${RPI_USER}@${RPI_IP}:${RPI_PORT}${NC}"
    
    # Test SSH connectivity
    echo ""
    echo -e "${BLUE}Testing SSH connection...${NC}"
    echo -e "${YELLOW}Note: You may be prompted for your SSH key passphrase${NC}"
    if ssh -p ${RPI_PORT} -o ConnectTimeout=10 ${RPI_USER}@${RPI_IP} exit; then
        echo -e "${GREEN}✓ SSH connection successful${NC}"
    else
        echo -e "${RED}✗ SSH connection failed${NC}"
        echo "Please check:"
        echo "1. Raspberry Pi IP address: ${RPI_IP}"
        echo "2. SSH is enabled on the Pi"
        echo "3. Network connectivity"
        echo "4. Enter the correct SSH key passphrase when prompted"
        echo ""
        echo -n "Press Enter to return to menu..."
        read
        return 1
    fi

    echo ""
    echo -e "${BLUE}Uploading and executing pigpio installation script...${NC}"
    echo ""

    # Create a temporary script file
    TEMP_SCRIPT="/tmp/install_pigpio_$(date +%s).sh"

    echo "Creating installation script..."
    cat << 'SCRIPT_EOF' > /tmp/local_pigpio_install.sh
#!/bin/bash

set -e  # Exit on any error

echo "=========================================="
echo "Starting pigpio installation on Raspberry Pi"
echo "=========================================="

# Step 0: Install dependencies
echo "Step 0: Installing dependencies..."
sudo apt update
sudo apt install -y git build-essential cmake pkg-config
echo "✓ Dependencies installed"

# Step 1: Clone the pigpio repository
echo ""
echo "Step 1: Preparing and cloning pigpio repository..."
echo "Cleaning up any existing pigpio directory..."
if [ -d "pigpio" ]; then
    echo "pigpio directory exists. Removing it first..."
    sudo rm -rf pigpio
else
    echo "No existing pigpio directory found."
fi

echo "Cloning fresh pigpio repository..."
git clone https://github.com/joan2937/pigpio.git
echo "✓ Repository cloned successfully"

# Step 2: Build and install from source
echo ""
echo "Step 2: Building and installing pigpio from source..."
cd pigpio
echo "Running make..."
make
echo "Running sudo make install..."
sudo make install
cd ..
echo "✓ pigpio built and installed from source"

# Step 3: Install additional packages
echo ""
echo "Step 3: Installing additional pigpio packages..."
sudo apt update

echo "Installing libpigpiod-if-dev (development headers)..."
sudo apt install -y libpigpiod-if-dev

echo "Checking for libpigpiod-if2 variants..."
if apt list libpigpiod-if2-1t64 2>/dev/null | grep -q libpigpiod-if2-1t64; then
    echo "Installing libpigpiod-if2-1t64 (client library interface)..."
    sudo apt install -y libpigpiod-if2-1t64
elif apt list libpigpiod-if2 2>/dev/null | grep -q libpigpiod-if2; then
    echo "Installing libpigpiod-if2 (client library interface)..."
    sudo apt install -y libpigpiod-if2
else
    echo "⚠ libpigpiod-if2 package not found, skipping (already built from source)"
fi

echo "Installing pigpio-tools (command-line tools)..."
sudo apt install -y pigpio-tools

echo "Installing python3-pigpio (Python binding)..."
sudo apt install -y python3-pigpio

echo "✓ Available packages installed"

# Step 4: Enable and start the daemon
echo ""
echo "Step 4: Enabling and starting pigpiod daemon..."
sudo systemctl enable pigpiod
echo "✓ pigpiod enabled to start on boot"
sudo systemctl start pigpiod
echo "✓ pigpiod daemon started"

# Step 5: Test if running
echo ""
echo "Step 5: Testing pigpiod status..."
echo "=========================================="
sudo systemctl status pigpiod --no-pager
echo "=========================================="

# Additional verification
echo ""
echo "Additional verification:"
if pgrep -x "pigpiod" > /dev/null; then
    echo "✓ pigpiod process is running"
else
    echo "⚠ pigpiod process not found"
fi

# Check if pigpiod is listening on default port
if ss -ltn | grep -q ":8888"; then
    echo "✓ pigpiod is listening on port 8888"
else
    echo "⚠ pigpiod not listening on port 8888"
fi

echo ""
echo "=========================================="
echo "pigpio installation completed!"
echo "=========================================="
echo ""
echo "You can now use:"
echo "- Command line tools like 'pigs' for GPIO control"
echo "- Python library: import pigpio"
echo "- C library: link with -lpigpio"
echo ""
echo "For remote access, pigpiod runs on port 8888 by default"
echo ""
echo "Quick test commands:"
echo "Try: pigs t 17"
echo "…to toggle GPIO 17 on/off"
SCRIPT_EOF

    # Upload script to Pi
    echo "Uploading script to Raspberry Pi..."
    if scp -P ${RPI_PORT} /tmp/local_pigpio_install.sh ${RPI_USER}@${RPI_IP}:${TEMP_SCRIPT}; then
        echo -e "${GREEN}✓ Script uploaded successfully${NC}"
    else
        echo -e "${RED}✗ Failed to upload script${NC}"
        rm /tmp/local_pigpio_install.sh
        echo ""
        echo -n "Press Enter to return to menu..."
        read
        return 1
    fi

    # Execute script on Pi
    echo ""
    echo "Executing installation on Raspberry Pi..."
    echo -e "${YELLOW}You may be prompted for sudo password during installation...${NC}"
    echo ""
    
    if ssh -p ${RPI_PORT} ${RPI_USER}@${RPI_IP} "chmod +x ${TEMP_SCRIPT} && bash ${TEMP_SCRIPT} && rm ${TEMP_SCRIPT}"; then
        # Clean up local temp file
        rm /tmp/local_pigpio_install.sh

        echo ""
        echo -e "${GREEN}=========================================="
        echo -e "Remote pigpio installation completed successfully!"
        echo -e "==========================================${NC}"
        echo ""
        echo -e "${YELLOW}Your Raspberry Pi is now ready for GPIO control!${NC}"
        echo ""
        echo "You can test the installation with:"
        echo -e "${CYAN}ssh ${RPI_USER}@${RPI_IP} 'pigs hwver'${NC}"
        echo ""
        echo "For Python remote control from your PC:"
        echo -e "${CYAN}import pigpio"
        echo -e "pi = pigpio.pi('${RPI_IP}')  # Connect to remote Pi${NC}"
    else
        echo ""
        echo -e "${RED}Installation failed. Check the output above for errors.${NC}"
        rm /tmp/local_pigpio_install.sh
        echo ""
        echo -n "Press Enter to return to menu..."
        read
        return 1
    fi
}

# Main program loop
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            echo ""
            install_local
            echo ""
            echo -n "Press Enter to return to menu..."
            read
            ;;
        2)
            echo ""
            install_remote
            echo ""
            echo -n "Press Enter to return to menu..."
            read
            ;;
        3)
            echo ""
            echo -e "${YELLOW}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo ""
            echo -e "${RED}Invalid option. Please choose 1, 2, or 3.${NC}"
            echo ""
            echo -n "Press Enter to continue..."
            read
            ;;
    esac
done
