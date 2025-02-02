import os
from typing import List

import pyperclip


def get_code_files(directory: str, extensions: List[str]) -> List[str]:
    """
    Recursively finds all code files in the given directory with specified extensions,
    strictly ignoring any path containing 'node_modules', '.next', or '.venv'.

    :param directory: Directory to search for code files.
    :param extensions: List of file extensions to include.
    :return: List of file paths for code files.
    """
    code_files = []
    for root, _, files in os.walk(directory):
        if "node_modules" in root or ".next" in root or ".venv" in root:
            continue

        code_files.extend(
            os.path.join(root, file)
            for file in files
            if any(file.endswith(ext) for ext in extensions)
        )
    return code_files


def read_files(file_paths: List[str], directory: str) -> str:
    """
    Reads the content of the given files and returns a combined string.

    :param file_paths: List of file paths to read.
    :param directory: Base directory for calculating relative paths.
    :return: Combined content of all files as a string.
    """
    content = []
    for file_path in file_paths:
        with open(file_path, "r") as file:
            relative_path = os.path.relpath(file_path, directory)
            content.append(f"--- {relative_path} ---\n")
            content.append(file.read())
            content.append("\n\n")
    return "".join(content)


def copy_code_to_clipboard() -> None:
    """
    Copies all code files from the current working directory to the clipboard.
    """
    extensions = [
        ".py",
        ".js",
        ".ts",
        ".html",
        ".css",
        ".tsx",
        ".jsx",
        ".swift",
        ".plist",
        ".xcbkptlist",
        ".toml",
        ".tf",
    ]
    directory = os.getcwd()
    code_files = get_code_files(directory, extensions)
    combined_content = read_files(code_files, directory)
    pyperclip.copy(combined_content)


if __name__ == "__main__":
    copy_code_to_clipboard()
    print("Code files have been copied to the clipboard.")
