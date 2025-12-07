import runpod
import subprocess
import os
import base64
import uuid

# Paths to the baked-in models
BINARY_PATH = "/usr/local/bin/sd"
MODEL_DIR = "/models"
DIFFUSION_MODEL = os.path.join(MODEL_DIR, "z_image_turbo-Q4_K.gguf")
LLM_MODEL = os.path.join(MODEL_DIR, "Qwen3-4B-Instruct-2507-Q4_K_M.gguf")
VAE_MODEL = os.path.join(MODEL_DIR, "ae.safetensors")
OUTPUT_DIR = "/tmp"

def handler(job):
    job_input = job['input']
    
    # 1. Parse Inputs (Set defaults for Z-Image Turbo)
    prompt = job_input.get("prompt", "castle")
    cfg_scale = str(job_input.get("cfg_scale", 1.0)) # Default 1.0 for Turbo
    width = str(job_input.get("width", 512))
    height = str(job_input.get("height", 1024))
    steps = str(job_input.get("steps", 10)) # Turbo needs fewer steps
    seed = str(job_input.get("seed", -1)) # -1 = random
    
    # Generate unique output filename
    unique_id = str(uuid.uuid4())
    output_filename = f"{unique_id}.png"
    output_path = os.path.join(OUTPUT_DIR, output_filename)

    # 2. Construct the Command
    # sd --diffusion-model ... --vae ... --llm ... -p ... --cfg-scale ... --diffusion-fa ...
    command = [
        BINARY_PATH,
        "--diffusion-model", DIFFUSION_MODEL,
        "--vae", VAE_MODEL,
        "--llm", LLM_MODEL,
        "-p", prompt,
        "--cfg-scale", cfg_scale,
        "--steps", steps,
        "-H", height,
        "-W", width,
        "--rng", "cuda",       # Force GPU RNG
        "--diffusion-fa",      # Flash Attention (Specific to your request)
        "-s", seed,
        "-o", output_path
    ]

    # print(f"Running command: {' '.join(command)}")

    try:
        # Execute binary
        result = subprocess.run(
            command, 
            check=True, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE
        )
        
        # 3. Process Output
        if os.path.exists(output_path):
            with open(output_path, "rb") as image_file:
                encoded_string = base64.b64encode(image_file.read()).decode('utf-8')
            
            # Cleanup
            os.remove(output_path)

            return {
                "status": "success",
                "image": encoded_string
            }
        else:
            print(f"STDOUT: {result.stdout.decode()}")
            print(f"STDERR: {result.stderr.decode()}")
            return {"error": "Output file was not generated. Check logs."}

    except subprocess.CalledProcessError as e:
        return {
            "error": "Generation failed", 
            "details": e.stderr.decode(),
            "stdout": e.stdout.decode()
        }
    except Exception as e:
        return {"error": str(e)}

# Start Worker
if __name__ == '__main__':
    runpod.serverless.start({"handler": handler})
