@Tags(['analyzer'])
import 'dart:convert';

import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:drift_dev/src/services/schema/schema_files.dart';
import 'package:drift_dev/src/writer/database_writer.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:test/test.dart';

import '../../analyzer/utils.dart';

void main() {
  test('writer integration test', () async {
    final state = TestState.withContent({
      'foo|lib/a.moor': '''
import 'main.dart';

CREATE TABLE "groups" (
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,

  UNIQUE(name)
);

CREATE VIRTUAL TABLE email USING fts5(sender, title, body);

CREATE TABLE group_members (
  "group" INT NOT NULL REFERENCES "groups"(id),
  user INT NOT NULL REFERENCES users(id),
  is_admin BOOLEAN NOT NULL DEFAULT FALSE,

  PRIMARY KEY ("group", user) ON CONFLICT REPLACE
);

CREATE TRIGGER delete_empty_groups AFTER DELETE ON group_members BEGIN
  DELETE FROM "groups"
    WHERE NOT EXISTS (SELECT * FROM group_members WHERE "group" = "groups".id);
END;

CREATE INDEX groups_name ON "groups"(name);

CREATE VIEW my_view AS SELECT id FROM "groups";
      ''',
      'foo|lib/main.dart': '''
import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get settings => text().named('setting').map(const SettingsConverter())();
}

class Settings {}

class SettingsConverter extends TypeConverter<Settings, String> {
  const SettingsConverter();

  String toSql(Settings s) => '';
  Settings fromSql(String db) => Settings();
}

@DriftDatabase(include: {'a.moor'}, tables: [Users])
class Database {}
      ''',
    }, options: const DriftOptions.defaults(modules: [SqlModule.fts5]));

    final file = await state.analyze('package:foo/main.dart');
    expect(state.session.errorsInFileAndImports(file), isEmpty);

    final result = file.currentResult as ParsedDartFile;
    final db = result.declaredDatabases.single;

    final schemaJson = SchemaWriter(db).createSchemaJson();
    expect(schemaJson, json.decode(expected));

    final schemaWithOptions = SchemaWriter(
      db,
      options: const DriftOptions.defaults(storeDateTimeValuesAsText: true),
    ).createSchemaJson();
    expect(
        schemaWithOptions['options'], {'store_date_time_values_as_text': true});
  });

  test('can generate code from schema json', () {
    final serializedSchema = json.decode(expected) as Map<String, dynamic>;

    final reader = SchemaReader.readJson(serializedSchema);
    final fakeDb = Database()..entities = [...reader.entities];

    // Write the database. Not crashing is good enough for us here, we have
    // separate tests for verification
    final writer = Writer(const DriftOptions.defaults(),
        generationOptions: const GenerationOptions(forSchema: 1));
    DatabaseWriter(fakeDb, writer.child()).write();
  });
}

const expected = r'''
{
    "_meta": {
        "description": "This file contains a serialized version of schema entities for drift.",
        "version": "1.0.0"
    },
    "options": {
      "store_date_time_values_as_text": false
    },
    "entities": [
        {
            "id": 0,
            "references": [

            ],
            "type": "table",
            "data": {
                "name": "groups",
                "was_declared_in_moor": true,
                "columns": [
                    {
                        "name": "id",
                        "getter_name": "id",
                        "moor_type": "ColumnType.integer",
                        "nullable": false,
                        "customConstraints": "NOT NULL PRIMARY KEY AUTOINCREMENT",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [
                            "primary-key",
                            "auto-increment"
                        ]
                    },
                    {
                        "name": "name",
                        "getter_name": "name",
                        "moor_type": "ColumnType.text",
                        "nullable": false,
                        "customConstraints": "NOT NULL",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [

                        ]
                    }
                ],
                "is_virtual": false,
                "constraints": [
                    "UNIQUE(name)"
                ]
            }
        },
        {
            "id": 1,
            "references": [

            ],
            "type": "table",
            "data": {
                "name": "users",
                "was_declared_in_moor": false,
                "columns": [
                    {
                        "name": "id",
                        "getter_name": "id",
                        "moor_type": "ColumnType.integer",
                        "nullable": false,
                        "customConstraints": null,
                        "defaultConstraints": "PRIMARY KEY AUTOINCREMENT",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [
                            "auto-increment",
                            "primary-key"
                        ]
                    },
                    {
                        "name": "name",
                        "getter_name": "name",
                        "moor_type": "ColumnType.text",
                        "nullable": false,
                        "customConstraints": null,
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [

                        ]
                    },
                    {
                        "name": "setting",
                        "getter_name": "settings",
                        "moor_type": "ColumnType.text",
                        "nullable": false,
                        "customConstraints": null,
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [

                        ],
                        "type_converter": {
                            "dart_expr": "const SettingsConverter()",
                            "dart_type_name": "Settings"
                        }
                    }
                ],
                "is_virtual": false
            }
        },
        {
            "id": 2,
            "references": [
                0,
                1
            ],
            "type": "table",
            "data": {
                "name": "group_members",
                "was_declared_in_moor": true,
                "columns": [
                    {
                        "name": "group",
                        "getter_name": "group",
                        "moor_type": "ColumnType.integer",
                        "nullable": false,
                        "customConstraints": "NOT NULL REFERENCES \"groups\"(id)",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [

                        ]
                    },
                    {
                        "name": "user",
                        "getter_name": "user",
                        "moor_type": "ColumnType.integer",
                        "nullable": false,
                        "customConstraints": "NOT NULL REFERENCES users(id)",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [

                        ]
                    },
                    {
                        "name": "is_admin",
                        "getter_name": "isAdmin",
                        "moor_type": "ColumnType.boolean",
                        "nullable": false,
                        "customConstraints": "NOT NULL DEFAULT FALSE",
                        "default_dart": "const CustomExpression<bool>('FALSE')",
                        "default_client_dart": null,
                        "dsl_features": [

                        ]
                    }
                ],
                "is_virtual": false,
                "constraints": [
                    "PRIMARY KEY (\"group\", user) ON CONFLICT REPLACE"
                ],
                "explicit_pk": [
                    "group",
                    "user"
                ]
            }
        },
        {
            "id": 3,
            "references": [
                2,
                0
            ],
            "type": "trigger",
            "data": {
                "on": 2,
                "refences_in_body": [
                    0,
                    2
                ],
                "name": "delete_empty_groups",
                "sql": "CREATE TRIGGER delete_empty_groups AFTER DELETE ON group_members BEGIN DELETE FROM \"groups\" WHERE NOT EXISTS (SELECT * FROM group_members WHERE \"group\" = \"groups\".id);END"
            }
        },
        {
            "id": 4,
            "references": [
                0
            ],
            "type": "index",
            "data": {
                "on": 0,
                "name": "groups_name",
                "sql": "CREATE INDEX groups_name ON \"groups\"(name);"
            }
        },
        {
            "id": 5,
            "references": [
                0
            ],
            "type": "view",
            "data": {
                "name": "my_view",
                "sql": "CREATE VIEW my_view AS SELECT id FROM \"groups\"",
                "dart_data_name": "MyViewData",
                "dart_info_name": "MyView",
                "columns": [
                    {
                        "name": "id",
                        "getter_name": "id",
                        "moor_type": "ColumnType.integer",
                        "nullable": false,
                        "customConstraints": null,
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [

                        ]
                    }
                ]
            }
        },
        {
            "id": 6,
            "references": [

            ],
            "type": "table",
            "data": {
                "name": "email",
                "was_declared_in_moor": true,
                "columns": [
                    {
                        "name": "sender",
                        "getter_name": "sender",
                        "moor_type": "ColumnType.text",
                        "nullable": false,
                        "customConstraints": "",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [

                        ]
                    },
                    {
                        "name": "title",
                        "getter_name": "title",
                        "moor_type": "ColumnType.text",
                        "nullable": false,
                        "customConstraints": "",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [

                        ]
                    },
                    {
                        "name": "body",
                        "getter_name": "body",
                        "moor_type": "ColumnType.text",
                        "nullable": false,
                        "customConstraints": "",
                        "default_dart": null,
                        "default_client_dart": null,
                        "dsl_features": [

                        ]
                    }
                ],
                "is_virtual": true,
                "create_virtual_stmt": "CREATE VIRTUAL TABLE email USING fts5(sender, title, body);"
            }
        }
    ]
}
''';
