"""
RESWAVE v3.0 - Mobile Android Package Generator
Packages the complete Flutter Android codebase, FastAPI backend, Firebase rules, and test suite.
Excludes web artifacts and temporary caches.
"""
import os
import shutil
import zipfile

def package_project():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    zip_filename = os.path.join(base_dir, "reswave_v3_android_complete.zip")
    
    # Artifact directory mirror
    artifact_dir = r"C:\Users\MKG\.gemini\antigravity\brain\18c8aff6-a1ce-4d85-a5da-c5d228abf9b3"
    artifact_zip = os.path.join(artifact_dir, "reswave_v3_android_complete.zip")

    exclude_dirs = {
        ".git", ".dart_tool", ".idea", "__pycache__", "build", ".gradle",
        "reswave_web"
    }
    exclude_files = {
        "reswave_full_code.zip", "reswave_baseline_v2.zip",
        "reswave_v3_android_complete.zip", "server.py"
    }

    print(f"Packaging ResWave v3.0 Android project from {base_dir}...")
    
    file_count = 0
    with zipfile.ZipFile(zip_filename, "w", zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(base_dir):
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            for file in files:
                if file in exclude_files or file.endswith(".pyc"):
                    continue
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, base_dir)
                zipf.write(full_path, os.path.join("reswave", rel_path))
                file_count += 1

    # Also mirror to artifact dir
    if os.path.isdir(artifact_dir):
        shutil.copy2(zip_filename, artifact_zip)
        print(f"Mirrored zip archive to artifact directory: {artifact_zip}")

    size_mb = os.path.getsize(zip_filename) / (1024 * 1024)
    print(f"Successfully generated reswave_v3_android_complete.zip ({file_count} files, {size_mb:.2f} MB)")

if __name__ == "__main__":
    package_project()
