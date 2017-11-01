## API

### Idee

Jeder Spiegel besitzt eine eigene API. Das Front- und Backend soll unäbhänig von der eigentlichen Logik funktionieren. So ist die API eigentlich das zentrale Herzstück des Spiegels, über welche die ganze Kommunikation läuft.

Das Frontend bezieht von der API die Daten, welche auf dem Frontend angezeigt werden. Der Benutzer konfiguriert also seine Datenquelle und die Daten werden dann über die API zur Verfügung gestellt, damit das Frontend auf diese Daten zugreifen kann.

Im Backend: Die Einstellungen von mirr.OS, die Konfiguration von mirr.OS, die Einstellugen der Modulinstanzen sowie die Anordnung der Module kann alles über die API abgefragt werden und anschliessend wieder gespeichert werden.

Mit diesem Setup ist es auch möglich, die API quasi als zentralen Hub im eigenen Netzwerk zu verwenden. So können z.B. aktuelle Daten von Lampenzuständen oder die Temperatur vom Thermostat von ein und der selben Quelle abgefragt werden und die Daten andersweitig verwenden. Die zur Verfügung stehenden Daten hängt von den Konfigurierten Datenquellen ab und wird natürlich auch für die Anzeige im Frontend verwendet.

So wird eine  zentrale und einheitliche Abfragemöglichkeit von verschiedenen Datenquellen angeboten, die alle gleich formatiert sind.

Hier gibt es z.B. das Anwendungbeispiel mit dem Tanken Modul. Es gibt verschiedene Datenquellen für ein bestimmtes Modul (Tankerkönig.de / Spritpreisrechner.at). Damit nicht zwei verschiedne Moduel entwickelt werden müssen, werden dann idealerweise die Daten dieser Datenquellen von der API einheitlich formatiert und zur Verfügung gestellt. In den Modul(-instanz)einstellungen gibt es dann die Möglichkeit auszuwählen, von welcher Datenquelle diese Instanz die Daten beziehen soll.

Quasi spielt die interne API hier eine Zwischenstelle. Mit den zur Verfügung stehenden Datenquelle und den vom Benutzer eingegeben Einstellungen (wie. z.B. Keys, Tokens oder Accounts) werden die Daten von der externen API abgefragt (z.B. Tanken), dann einheitlich formatiert und dann über die interne API (z.B. JSON und/oder XML) zur Verfügung gestellt.

Ein weiterer Vorteil dieser Lösung ist, dass so alles von der Darstellung unabhängig ist.
Sei es, wenn jemand sein eigenes Interface für die Steuerung für mirr.OS bauen will, später mal eine mobile native Applikation veröffentlicht werden soll oder es letztendlich nur für die Anzeige im Frontend verwendet wird, die API kann immer als zentraler Kommunkationspunkt genutzt werden.


### Groups

`Groups` regeln, welche `Modules` und `Sources` miteinander funktionieren.<br>

So haben zum Beispiel das `Module` `calendar_week` und die `Source` `Google Kalender` beide die `Group` `calendar`. Über diese Beziehung wird festgelegt, dass `Modules` und `Sources` der gleichen Gruppe miteinander kompatibel sind.

#### Endpunkte

`/api/groups`<br>
`/api/groups/{group_name}`

#### Beziehungen

Feld | Model | Identifier | Beschreibung
---  | ---   | ---        | ---
category | `Category` | `Category.name` | Die Kategoriezugehörigkeit dieser Gruppe
sources | `Source` | - | Alle Datenquellen die dieser Gruppe angehören
modules | `Module` | - | Alle Module die dieser Gruppe angehören


#### Aufbau des Models

```javascript
{
	"name": String,
	"model": Model,
	"category": Category,
	"source_structure": Object,
	"modules": [Module],
	"sources": [Source]
}
```

#### Beispiel

```javascript
{
	"name": "calendar",
	"model": "group",
	"source_structure": {},
	"category": "producivity",
	"modules": [...],
	"sources": [...]
}
```

<br>
___
<br>




### Modules

#### Endpunkte

`/api/modules`<br>
`/api/modules/{module_name}`<br>

#### Beziehungen

Feld | Model | Identifier | Beschreibung
---  | ---   | ---        | ---
group | `Group` | `Group.name` | Die Gruppe dieses Modules
category | `Category` | `Category.name` | Die Kategorie dieses Modules
sources | `Source` | - | Die mit diesem Modul kompatiblen Datenquellen
languages | `Language` | - | Die zu verfügbaren stehenden Sprachen dieses Moduls
instances | `ModuleInstance` | - | Instanzen, die es von diesem Modul gibt


#### Aufbau des Models

```javascript
{
	"name": String,
	"group": Group,
	"model": Model,
	"author": String,
	"category": Category,
	"version": String,
	"path": String,
	"website": String,
	"repository": String,
	"sizes": Array,
	"sources": [Source],
	"languages": [Language],
	"instances": [ModuleInstance]
}
```

#### Beispiel

```javascript
{
	"name": "fuel",
	"group": "fuel",
	"model": "module",
	"author": "Marco Roth",
	"category": "productiviy",
	"version": "1.0.0",
	"path": "/api/sources/modules/fuel",
	"website": "https://glancr.de/modules/productivity/fuel/",
	"repository": "https://github.com/marcoroth/mirrOS_fuel",
	"sizes": [sizes.json],
	"sources": [...],
	"languages": [...],
	"instances": [...]
}
```


<br>
___
<br>

### ModuleInstances

#### Endpunkte

`/api/modules/{module_name}/{instance_id}`<br>
`/api/modules/{module_name}/{instance_id}/settings`<br>

#### Beziehungen

Feld | Model | Identifier | Beschreibung
---  | ---   | ---        | ---
module | `Module` | `Module.name` | Das übergeordnete Modul dieser Instanz


#### Aufbau des Models

```javascript
{
	"id": Integer,
	"module": Module,
	"model": Model,
	"path": String,
	"settings": Object,
	"config": {
		"width": Integer,
		"height": Integer,
		"col": Integer,
		"row": Integer
	}
}
```

#### Beispiel

```javascript
{
	"id": 1,
	"module": "fuel",
	"model": "module_instance",
	"path": "/api/modules/fuel/1",
	"settings": {},
	"config": {
		"width": 6,
		"height": 3,
		"col": 1,
		"row": 1
	}
}
```


<br>
___
<br>


### Sources

#### Endpunkte

`/api/sources`<br>
`/api/sources/{source_name}`<br>

#### Beziehungen

Feld | Model | Identifier | Beschreibung
---  | ---   | ---        | ---
group | `Group` | `Group.name` | Die Gruppe dieser Datenquelle
category | `Category` | `Category.name` | Die Kategorie dieser Datenquelle
modules | `Module` | - | Die mit dieser Datenquelle kompatiblen Module
languages | `Language` | - | Die zu verfügbaren stehenden Sprachen dieser Datenquelle
instances | `SourceInstance` | - | Instanzen, die es von diesem Datenquelle gibt

#### Aufbau des Models

```javascript
{
	"name": String,
	"group": Group,
	"model": Model,
	"category": Category,
	"version": String,
	"author": String,
	"path": String,
	"website": String,
	"modules": [Module],
	"languages": [Language],
	"instances": [SourceInstance]
}
```

#### Beispiel

```javascript
{
	"name": "google",
	"group": "calendar",
	"model": "source",
	"category": "productivity",
	"version": "1.0.0",
	"author": "Mattes Angelus",
	"path": "/api/sources/calendar/google/",
	"website": "http://glancr.de/sources/google/",
	"modules": [...],
	"languages": [...],
	"instances": [...]
}
```


<br>
___
<br>


### SourceInstances

#### Endpunkte

`/api/sources/{source_name}/{instance_id}`<br>
`/api/modules/{source_name}/{instance_id}/settings`<br>
`/api/modules/{source_name}/{instance_id}/data`<br>

#### Beziehungen

Feld | Model | Identifier | Beschreibung
---  | ---   | ---        | ---
category | `Category` | `Category.name` | Die Kategoriezugehörigkeit dieses Typs
sources | `Source` | - | Die vom diesem Typ verfügbaren Datequellen
modules | `Module` | - | Die vom diesem Typ verfügbaren Module


#### Aufbau des Models

```javascript
{
	"id": Integer,
	"source": Source,
	"model": Model,
	"path": String,
	"data": Object,
	"settings": Object
}
```

#### Beispiel


```javascript
{
	"id": 1,
	"source": "google",
	"model": "source_instance",
	"path": "/api/sources/google/1",
	"data": {},
	"settings": {}
}
```

<br>
___
<br>


### Categories

#### Endpunkte

`/api/categories`<br>
`/api/categories/{category_name}`

#### Beziehungen

Feld | Model | Identifier | Beschreibung
---  | ---   | ---        | ---
sources | `Source` | - | Datenquellen, die dieser Kategorie angehören
modules | `Module` | - | Module, die dieser Kategorie angehören

#### Aufbau des Models


```javascript
{
	"name": String,
	"model": Model,
	"path": String,
	"website": String,
	"modules": [Module],
	"sources": [Source]
}
```

#### Beispiel

```javascript
{
	"name": "productivity",
	"model": "category",
	"path": "/api/categories/productivity/",
	"website": "http://glancr.de/modules/productivity/",
	"modules": [...],
	"sources": [...]
}
```

<br>
___
<br>


### Languages

#### Endpunkte

`/api/languages`<br>
`/api/languages/{language_name}`

#### Beziehungen

Feld | Model | Identifier | Beschreibung
---  | ---   | ---        | ---
sources | `Source` | - | Datenquellen, die diese Sprache unterstützen
modules | `Module` | - | Module, die diese Sprache unterstützen
translations | `Translation` | - | Übersetzungen, die es in dieser Sprache gibt


#### Aufbau des Models

```javascript
{
	"name": String,
	"code": String,
	"model": Model,
	"path": String,
	"modules": [Module],
	"sources": [Source],
	"translations": [Translation]
}
```

#### Beispiel

```javascript
{
	"name": "Deutsch",
	"code": "de_DE",
	"model": "language",
	"path": "/api/languages/de_DE",
	"modules": [...],
	"sources": [...],
	"translations": [...]
}
```



<br>
___
<br>

### Translation

#### Endpunkte

`/api/translations`<br>
`/api/translations/system`<br>
`/api/translations/{module_name}`<br>
`/api/translations/{source_name}`<br>
`/api/translations/{language_name}`<br>
`/api/translations/{language_name}/system`<br>
`/api/translations/{language_name}/{module_name}`<br>
`/api/translations/{language_name}/{source_name}`<br>


#### Beziehungen

Feld | Model | Identifier | Beschreibung
---  | ---   | ---        | ---
source | `Source` | `Source.name` | Datenquelle, für welches diese Übersetzung ist
module | `Module` | `Module.name` | Modul, für welches diese Übersetzung ist
language | `Langaue` | `Langaue.code` | Sprache, in welcher diese Übersetzung ist


#### Aufbau des Models

```javascript
{
	"name": String,
	"model": Model,
	"language": Language,
	"module": Module,
	"source": Source,
	"data": Object
}
```

#### Beispiel

```javascript
{
	"name": "fuel-de_DE",
	"model": "translation",
	"langugage": "de_DE"
	"module": "fuel",
	"source": null,
	"data": {
		"fuel_title": "Tanken",
		"fuel_description": "Modul zum Anzeigen der billgsten Tankstelle in deiner Nähe"
	}
}
```

<br>
___
<br>

### Scripts

#### Endpunkte

`/api/scripts`<br>
`/api/scripts/{script_name}`<br>
`/api/scripts/{script_name}/trigger`<br>
`/api/scripts/{script_name}/toggle`<br>
`/api/scripts/{script_name}/on`<br>
`/api/scripts/{script_name}/off`<br>

#### Beziehungen

Feld | Model | Identifier | Beschreibung
---  | ---   | ---        | ---
module | `Module` | `Module.name` | Modul, zu welchem dieses Script gehört

#### Aufbau des Models

```javascript
{
	"name": String,
	"model": Model,
	"module": Module,
	"button_type": ["toggle", "once"],
	"path": String,
	"type": String,
	"exec": String,
	"settings": Object
}
```

#### Beispiel

```javascript
{
	"name": "lamps_on",
	"model": "script",
	"module": Module,
	"button_type": "toggle"
	"path": "/scripts/hue/lamps.sh",
	"type": "Shell",
	"exec": "bash {path}",
	"settings": {
		"color": "blue",
		"brightness": 90,
		"room": "kitchen"
	}
}
```

<br>
___
<br>


### Beispiel-Abfragen (vereinfacht)


### `/api`

```javascript
// Example: /api

{
	"name": "Glancr mirrOS",
	"version": "1.0.0",
	"webserver": "Apache 2",
	"device": "Raspberry 3",
	"os": "Raspian X.Y",
	"endpoints": [
		"/api/info",
		"/api/user",
		...
	],
	"documentation": "https://glancr.de/api-documentation"
}

```


### `/api/user`

```javascript
// Example: /api/user

{
	"name": "Marco Roth",
	"firstname": "Marco",
	"lastname": "Roth",
	"email": "marco.roth@intergga.ch",
	"city": "Basel",
	"country": "CH",
	"language": "de_DE"
}
```


### `/api/groups`

```javascript
// Example: /api/groups

{
	"groups": [
		{
			"name": "calendar",
			"modules": [
				{ "name": "calendar_week", ... },
				{ "name": "calendar_today", ... },
				{ "name": "calendar_next", ... }
			],
			"sources": [
				{ "name": "google", ... },
				{ "name": "icloud", ... },
				{ "name": "ical", ... }
			]
		},
		{
			"name": "fuel",
			"modules": [
				{ "name": "fuel", ... }
			],
			"sources": [
				{ "name": "Tankerkönig", ... },
				{ "name": "Spritpreisrechner", ... }
			]
		}
	]
}

```


### `/api/groups/{group_name}`

```javascript

// Example: /api/groups/calendar

{

}

```

### `/api/sources`

```javascript

// Example: /api/sources

{
	"sources": [
		{
			"name": "google",
			"group": "calendar",
			"version": "1.0.0",
			"author": "Mattes Angelus",
			"path": "/api/sources/calendar/google",
			"website": "https://google.com"
		},
		{
			"name": "tankerkoenig",
			"group": "fuel",
			"version": "1.0.0",
			"path": "/api/sources/fuel/tankerkoenig",
			"website": "https://google.com"
		}
	]
}

```

### `/api/sources/{source_name}`

```javascript

// Example: /api/sources/calendar

{
	"group": "calendar",
	"sources": [
		{
			"name": "google",
			"group": "calendar",
			"version": "1.0.0",
			"author": "Marco Roth",
			"path": "/api/sources/calendar/google"
		},
		{
			"name": "icloud",
			"group": "calendar",
			"version": "1.0.0",
			"author": "Marco Roth",
			"path": "/api/sources/calendar/icloud"
		},
		{
			"name": "ical",
			"group": "calendar",
			"version": "1.0.0",
			"author": "Marco Roth",
			"path": "/api/sources/calendar/ical"
		}
	]
}

```


### `/api/sources/{source_name}/{instance_id}`

```javascript

// Example: /api/sources/calendar/1/

{

}

```


### `/api/sources/{source_name}/{instance_id}/settings`

```javascript

// Example: /api/sources/calendar/1/settings

{

}

```


### `/api/sources/{source_name}/{instance_id}/data`

```javascript

// Example: /api/sources/calendar/1/data

{

}

```


### `/api/modules`

```javascript

// Example: /api/modules

{
	"modules": [
		{
			"name": "fuel",
			"group": "fuel",
			"author": "Marco Roth",
			"version": "1.0.0",
			"path": "/api/sources/fuel/fuel"
		},
		{
			"name": "calendar_week",
			"group": "calendar",
			"author": "Mattes Angelus",
			"version": "1.0.0",
			"path": "/api/sources/calendar/calendar_week"
		}
	]
}

```


### `/api/modules/{module_name}`

```javascript
// Example: /api/modules/fuel

{

}

```


### `/api/modules/{module_name}/{instance_id}`

```javascript
// Example: /api/modules/fuel/1

{

}

```

### `/api/modules/{module_name}/{instance_id}/settings`

```javascript
// Example: /api/modules/fuel/1/settings

{

}

```


### `/api/categories`

```javascript
// Example: /api/categories

{
	"categories": [
		{

		}
	]
}

```


### `/api/categories/{category_name}`

```javascript
// Example: /api/modules/categories/productivity

{

}

```
