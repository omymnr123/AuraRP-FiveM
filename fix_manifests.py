import os

mlo_dir = r"d:\GTA Server2\txData\FiveMBasicServerCFXDefault_91CD27.base\resources\[mlo]"
count = 0

for root, dirs, files in os.walk(mlo_dir):
    for file in files:
        if file.lower() == "_manifest.ymf":
            # Find the resource name (the folder inside [mlo])
            rel_path = os.path.relpath(root, mlo_dir)
            resource_name = rel_path.split(os.sep)[0]
            
            old_path = os.path.join(root, file)
            new_name = f"{resource_name}_manifest.ymf"
            new_path = os.path.join(root, new_name)
            
            try:
                os.rename(old_path, new_path)
                print(f"Renamed: {old_path} -> {new_name}")
                count += 1
            except Exception as e:
                print(f"Error renaming {old_path}: {e}")

print(f"Total renamed: {count}")
