#!/usr/bin/env python
import os
import re

from setuptools import find_namespace_packages
from setuptools import setup

this_directory = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(this_directory, "README.md")) as f:
    long_description = f.read()

package_name = "dbt-excel"


def _dbt_excel_version():
    _version_path = os.path.join(this_directory, "dbt", "adapters", "excel", "__version__.py")
    _version_pattern = r"""version\s*=\s*["'](.+)["']"""
    with open(_version_path) as f:
        match = re.search(_version_pattern, f.read().strip())
        if match is None:
            raise ValueError(f"invalid version at {_version_path}")
        return match.group(1)


package_version = _dbt_excel_version() + "rc2"
description = """The excel adapter plugin for dbt (data build tool)"""

setup(
    name=package_name,
    version=package_version,
    description=description,
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="Cor Zuurmond,Dumky de Wilde,Juan Perafan,Henk Griffioen",
    author_email="Cor.Zuurmond@xebia.com,Dumky.deWilde@xebia.com,Henk.Griffioen@xebia.com, juan.perafan@xebia.com",
    url="https://github.com/godatadriven/dbt-excel",
    packages=find_namespace_packages(include=["dbt", "dbt.*"]),
    include_package_data=True,
    install_requires=[
        "dbt-duckdb~=1.4.0",
        "pandas>=1.0.0,<3.0.0",
        "pyarrow>=9.0.0",
        "openpyxl>=3.0.0,<4.0.0",
    ],
    extras_require={
        "glue": ["boto3", "mypy-boto3-glue"],
        "test": ["pytest", "dbt-tests-adapter"],
    },
)
