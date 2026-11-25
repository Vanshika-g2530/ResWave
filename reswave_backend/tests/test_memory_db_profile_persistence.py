import json
import tempfile
import unittest
from pathlib import Path

from app.core.memory_db import MemoryDatabase


class MemoryDatabaseProfilePersistenceTests(unittest.TestCase):
    def test_firestore_backed_profiles_are_not_saved_to_json(self):
        with tempfile.TemporaryDirectory() as directory:
            data_file = Path(directory) / "reswave_data_store.json"
            database = MemoryDatabase(data_file=str(data_file))
            database.cache_user_profile(
                "firestore-user",
                {"uid": "firestore-user"},
                firestore_backed=True,
            )
            database.cache_user_profile(
                "local-user",
                {"uid": "local-user"},
            )

            database.save_to_disk()
            saved_users = json.loads(data_file.read_text(encoding="utf-8"))["users"]

        self.assertNotIn("firestore-user", saved_users)
        self.assertIn("local-user", saved_users)


if __name__ == "__main__":
    unittest.main()
