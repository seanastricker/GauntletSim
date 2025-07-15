from PIL import Image
import os

# Convert Office_Design_1.gif to PNG
gif_path = "Office_Design_1.gif"
png_path = "Office_Design_1.png"

# Open the GIF
gif = Image.open(gif_path)

# Save the first frame as PNG
gif.save(png_path, "PNG")

print(f"Converted {gif_path} to {png_path}")

# Also convert Office_Design_2
gif_path2 = "Office_Design_2.gif"
png_path2 = "Office_Design_2.png"

gif2 = Image.open(gif_path2)
gif2.save(png_path2, "PNG")

print(f"Converted {gif_path2} to {png_path2}") 