import struct
import os
import sys

def extract_approx_coords(filepath):
    try:
        with open(filepath, 'rb') as f:
            data = f.read()
    except Exception as e:
        return None

    # Scan for 3 consecutive floats (X, Y, Z) that look like GTA V coordinates
    valid_coords = []
    
    # Iterate through the binary data in 4-byte chunks
    for i in range(0, len(data) - 12, 4):
        try:
            x, y, z = struct.unpack('<fff', data[i:i+12])
            # GTA V Map bounds:
            # X: -4500 to 4500
            # Y: -4000 to 8000
            # Z: -100 to 1000
            # We want to ignore 0,0,0 and small numbers (rotations)
            if (abs(x) > 50 and abs(x) < 5000 and 
                abs(y) > 50 and abs(y) < 8000 and 
                z > -200 and z < 1000):
                
                # Further filter: Z shouldn't be exactly perfectly round unless it's a specific height, but many are.
                # To prevent garbage data, we can check if there are multiple similar coords nearby.
                valid_coords.append((x, y, z))
        except:
            pass

    if not valid_coords:
        return None
    
    # We will likely get a lot of coordinates for entities.
    # Let's average them to find the center of the MLO.
    # First, let's filter out outliers (garbage data)
    avg_x = sum(c[0] for c in valid_coords) / len(valid_coords)
    avg_y = sum(c[1] for c in valid_coords) / len(valid_coords)
    
    # Keep only coords that are relatively close to the average to avoid reading random memory bytes as valid floats
    filtered = [c for c in valid_coords if abs(c[0] - avg_x) < 500 and abs(c[1] - avg_y) < 500]
    
    if not filtered:
        return None
        
    final_x = sum(c[0] for c in filtered) / len(filtered)
    final_y = sum(c[1] for c in filtered) / len(filtered)
    final_z = sum(c[2] for c in filtered) / len(filtered)
    
    return (final_x, final_y, final_z)

mlo_dir = r"d:\GTA Server2\txData\FiveMBasicServerCFXDefault_91CD27.base\resources\[mlo]"

for root, dirs, files in os.walk(mlo_dir):
    for file in files:
        if file.endswith('.ymap'):
            filepath = os.path.join(root, file)
            coords = extract_approx_coords(filepath)
            if coords:
                print(f"[{file}] -> X: {coords[0]:.2f}, Y: {coords[1]:.2f}, Z: {coords[2]:.2f}")
