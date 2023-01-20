import os

import pandas as pd
import pytest
import yaml
from dbt.tests.util import run_dbt

sources_schema_yml = """version: 2
sources:
  - name: external_source
    meta:
      external_location: "./seeds/{name}.xlsx"
    tables:
      - name: seeds_source
        description: "A source table"
        columns:
          - name: id
            description: "An id"
            tests:
              - unique
              - not_null
      - name: seeds_ost
        identifier: "seeds_other_source_table"
        meta:
          external_location: "./seeds/{identifier}.xlsx"
"""

models_source_model_sql = """select * from {{ source('external_source', 'seeds_source') }}
"""

models_multi_source_model_sql = """select * from {{ source('external_source', 'seeds_source') }}
  inner join {{ source('external_source', 'seeds_ost') }} USING (id)
"""


class TestExternalSources:
    @pytest.fixture(scope="class", autouse=True)
    def setEnvVars(self):
        os.environ["DBT_TEST_SCHEMA_NAME_VARIABLE"] = "test_run_schema"

        yield

        del os.environ["DBT_TEST_SCHEMA_NAME_VARIABLE"]

    @pytest.fixture(scope="class")
    def models(self):
        return {
            "schema.yml": sources_schema_yml,
            "source_model.sql": models_source_model_sql,
            "multi_source_model.sql": models_multi_source_model_sql,
        }

    def run_dbt_with_vars(self, project, cmd, *args, **kwargs):
        vars_dict = {
            "test_run_schema": project.test_schema,
        }
        cmd.extend(["--vars", yaml.safe_dump(vars_dict)])
        return run_dbt(cmd, *args, **kwargs)

    def test_external_sources(self, project):
        # abusing the 'seeds' directory a little bit here, but it works
        seeds_source = pd.DataFrame({"id": [1, 4, 7], "a": [2, 5, 8], "b": [3, 6, 9]})
        seeds_source.to_excel("seeds/seeds_source.xlsx", index=False)
        seeds_other_source_table = pd.DataFrame(
            {"id": [1, 4, 7], "c": [2, 5, 8], "d": [3, 6, 9]}
        )
        seeds_other_source_table.to_excel(
            "seeds/seeds_other_source_table.xlsx", index=False
        )

        results = self.run_dbt_with_vars(project, ["run"])
        assert len(results) == 2

        test_results = self.run_dbt_with_vars(project, ["test"])
        assert len(test_results) == 2
