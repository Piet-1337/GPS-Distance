# GPS Distance Calculator Script

This PowerShell script connects to a GPS receiver via a specified COM port to calculate the distance between two geographical points using the Haversine formula. The script provides real-time GPS data, including satellite information, and displays the calculated distance along with a detailed breakdown of the calculation.

## Features

- **Real-Time GPS Data**: Continuously updates and displays GPS fix quality, the number of satellites in use, and current position.
- **Satellite Information**: Separately tracks satellites in view for GPS, GLONASS, and GALILEO systems.
- **Distance Calculation**: Utilizes the Haversine formula to calculate the distance between two recorded geographical positions.
- **Interactive Console**: User-friendly interface with color-coded output for easy navigation.
- **Step-by-Step Instructions**: Guides users through the process with clear instructions for recording start and end positions.
- **Comprehensive Summary**: Provides a detailed summary of the calculated distance, including intermediate values and the full Haversine formula for manual verification.

## Usage

1. **Connect GPS Device**: Ensure your GPS receiver is connected to a COM port on your computer.
2. **Run Script**: Execute the PowerShell script and input the appropriate COM port (e.g., `COM5`) when prompted.
3. **Record Positions**:
   - Press 'S' to record the start position.
   - Move to a new location if desired, then press 'E' to record the end position.
4. **View Results**: The script will display a summary of the start and end positions, the calculated distance, and the details of the calculation.

## Requirements

- A GPS receiver capable of outputting NMEA sentences.
- PowerShell installed on your computer.
- Basic understanding of PowerShell and GPS operations.

## Note

This script is intended for educational and testing purposes. Ensure to test in a safe and open environment to avoid any potential hazards.

## Contribution

Feel free to fork the repository and submit pull requests for improvements or additional features. Your contributions are welcome!
