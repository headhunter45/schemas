FROM lipanski/docker-static-website:latest

# Copy your static files directly into the web root
COPY . .
