import unittest
from unittest import mock

import dbt.flags as flags
from dbt.adapters.excel import ExcelAdapter
from tests.unit.utils import config_from_parts_or_dicts, mock_connection


class TestExcelAdapter(unittest.TestCase):
    def setUp(self):
        pass
        flags.STRICT_MODE = True

        profile_cfg = {
            "outputs": {
                "test": {
                    "type": "excel",
                    "path": ":memory:",
                }
            },
            "target": "test",
        }

        project_cfg = {
            "name": "X",
            "version": "0.1",
            "profile": "test",
            "project-root": "/tmp/dbt/does-not-exist",
            "quoting": {
                "identifier": False,
                "schema": True,
            },
            "config-version": 2,
        }

        self.config = config_from_parts_or_dicts(project_cfg, profile_cfg)
        self._adapter = None

    @property
    def adapter(self):
        if self._adapter is None:
            self._adapter = ExcelAdapter(self.config)
        return self._adapter

    # TODO: Fix this test
    #     @mock.patch("dbt.adapters.excel.connections.duckdb")
    #     def test_acquire_connection(self, connector):
    #         connection = self.adapter.acquire_connection("dummy")
    #
    #         connector.connect.assert_not_called()
    #         connection.handle
    #         self.assertEqual(connection.state, "open")
    #         self.assertNotEqual(connection.handle, None)
    #         connector.connect.assert_called_once()

    def test_cancel_open_connections_empty(self):
        self.assertEqual(len(list(self.adapter.cancel_open_connections())), 0)

    def test_cancel_open_connections_main(self):
        key = self.adapter.connections.get_thread_identifier()
        self.adapter.connections.thread_connections[key] = mock_connection(
            "main"
        )
        self.assertEqual(len(list(self.adapter.cancel_open_connections())), 0)
