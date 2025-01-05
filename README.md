# Bachelor's Thesis

This repository contains the code and documentation for my Bachelor's thesis project which is a mobile app for EV chargers.

## Project Overview

The goal of this project is to create a mobile app that will allow user to check EV chargers locations and availability. The app is developed using Flutter for the frontend and FastAPI for the backend.

## Table of Contents
- [Installation](#installation)
- [Configuration](#configuration)
- [Running the application](#running-the-application)
- [Information](#information)
- [Creating local database](#creating-local-database)
- [Running tests](#running-tests)

## Installation

To install and run this project, follow these steps:

1. Clone the repository:
    ```bash
    git clone https://github.com/jakub-prokopiuk/Bachelor-s-thesis.git
    ```
2. Navigate to the backend directory of this project:
    ```bash
    cd Bachelor-s-thesis/backend
    ```
3. Create virtual environment:
    ```bash
    python3 -m venv .venv
    ```
4. Activate virtual environment:
    ```bash
    source .venv/bin/activate
    ```
5. Install dependencies:
    ```bash
    pip install -r requirements.txt
    ```
6. Ensure you have Flutter installed. If not, follow the instructions [here](https://flutter.dev/docs/get-started/install).

7. Install the frontend dependencies:
    ```bash
    cd ../frontend
    flutter pub get
    ```

## Configuration

To configure the application, follow these steps:
1. Check your IP address by running:
    ```bash
    ifconfig
    ```
    You will need this address to configure the backend server.
1. Create a `.env` file in the frontend directory and add the following environment variable:
    ```bash
    API_URL=<YOUR_IFCONFIG_IP_ADDRESS>:8000
    ```
2. Create a `.env` file in the backend directory and add the following environment variables:
    ```bash
    API_KEY=<YOUR_TOMTOM_API_KEY>
    DATABASE_URL = <YOUR_DATABASE_URL>
    ```
    If you want to use local database, you should use the following URL:
    ```bash
    DATABASE_URL = sqlite:///ev_chargers.db
    ```
    ```bash
    SECRET_KEY = <SECRET_KEY_FOR_JWT>
    ALGORITHM = <ALGORITHM_FOR_JWT> 
    ACCESS_TOKEN_EXPIRE_MINUTES = <TIME_FOR_JWT_EXPIRATION>
    SENDER_EMAIL = <EMAIL_FOR_SENDING_EMAILS_TO_USERS>
    SENDER_SMTP = <YOUR_MAIL_SMTP_SERVER>
    SENDER_PASSWORD = <YOUR_MAIL_PASSWORD>
    ```
3. To populate the database with data, run the following command:
    ```bash
    PYTHONPATH=$(pwd) python3 backend/scripts/update_db.py
    ```
## Running the application

1. Navigate to the frontend directory and run the Flutter app:
    ```bash
    flutter run
    ```
2. In another terminal window run the backend from backend directory:
    ```bash
    uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
    ```

## Information
Your backend server should be running on `http://localhost:8000` and the frontend app should be running on your emulator or physical device (I recommend physical device for better performance).

## Creating local database
Create a local database by running the following command with active virtual environment:
    ```bash
    python3 backend/scripts/create_db.py
    ```
    This should create a local database with the name `ev_chargers.db` in the backend directory.

## Running tests
1. To run tests for the backend, navigate to the backend directory and run the following command:
    ```bash
    pytest
    ```