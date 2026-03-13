#!/usr/bin/env python3
"""
QR Code Scanner for Zip Files
Reads zip file in memory and scans all QR codes inside
"""

import zipfile
from io import BytesIO
from PIL import Image
from pyzbar.pyzbar import decode

def scan_qr_from_image_data(image_data):
    """Scan QR code from image bytes without writing to disk"""
    try:
        # Open image from bytes
        img = Image.open(BytesIO(image_data))
        
        # Decode QR codes using pyzbar
        decoded_objects = decode(img)
        
        if decoded_objects:
            # Return data from first QR code found
            return decoded_objects[0].data.decode('utf-8')
        
        return None
        
    except Exception as e:
        return None

def scan_zip_for_qr_codes(zip_path):
    """Read zip file and scan all QR codes inside"""
    print(f"[*] Opening zip file: {zip_path}")
    
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        # Get list of all files in zip
        file_list = zip_ref.namelist()
        image_files = [f for f in file_list if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.gif'))]
        
        print(f"[*] Found {len(image_files)} image files in zip")
        print("[*] Starting QR code scan...\n")
        
        scanned_count = 0
        found_count = 0
        
        for img_file in image_files:
            scanned_count += 1
            
            # Read image data directly from zip (in memory)
            image_data = zip_ref.read(img_file)
            
            # Scan QR code
            result = scan_qr_from_image_data(image_data)
            
            if result:
                found_count += 1
                print(f"[✓] QR Code #{found_count} - File: {img_file} - Data: {result}")
                print()
            
            # Progress indicator every 100 files
            if scanned_count % 100 == 0:
                print(f"[*] Progress: {scanned_count}/{len(image_files)} scanned, {found_count} QR codes found")
        
        print(f"\n[*] Scan complete!")
        print(f"[*] Total scanned: {scanned_count}")
        print(f"[*] QR codes found: {found_count}")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python3 scan_qr.py <zip_file>")
        sys.exit(1)
    
    zip_file = sys.argv[1]
    scan_zip_for_qr_codes(zip_file)
