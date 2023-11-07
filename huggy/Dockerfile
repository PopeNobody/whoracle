# Use the official Python image as the base image
FROM python:3.8-slim-buster

# Set the working directory in the container
WORKDIR /app

# Copy the requirements.txt file to the container
COPY requirements.txt .

# Install the Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install the Hugging Face library
RUN pip install --no-cache-dir transformers

# Copy the application files to the container
COPY app.py /app

# Set the command to run the application
CMD ["python", "app.py"]
