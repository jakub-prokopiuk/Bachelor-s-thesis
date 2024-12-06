# Bachelor's Thesis

This repository contains the code and documentation for my Bachelor's thesis project.

## Project Overview

The goal of this project is to create a mobile app that will allow user to check EV chargers status on the map and navigate to it.

## Table of Contents
- [Installation](#installation)

## Installation

To install and run this project, follow these steps:

1. Clone the repository:
    ```bash
    git clone https://github.com/yourusername/your-repo-name.git
    ```
2. Navigate to the backend of project:
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
6. Run the backend:
    ```bash
    uvicorn app.main:app --reload
    ```
7. In another terminal, navigate to the frontend of project:
    ```bash
    cd ../frontend
    ```
8. Ensure you have Flutter installed. If not, follow the instructions [here](https://flutter.dev/docs/get-started/install).

9. Install the Flutter dependencies:
    ```bash
    flutter pub get
    ```

9. Run the Flutter app:
    ```bash
    flutter run
    ```