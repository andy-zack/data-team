# Data Team Analytics Dashboard (Beta)

## Overview

This Shiny application integrates OpenAI's API for transforming natural language questions into SQL queries against a SQLite database with [chinook](https://github.com/lerocha/chinook-database/tree/master) data (CRM from a fictional music store). It demonstrates the blend of natural language processing and data analysis, offering an intuitive querying and visualization interface. The application comprises API communication (`api_helpers.R`), server logic (`server.R`), and user interface (`ui.R`), enabling users to explore data through natural language.

## Requirements

- R with `shiny`, `RSQLite`, `httr`, `jsonlite`, `here`, `DT`.
- OpenAI API key.

## Installation

1. Clone the repository.
2. Install R packages with `install.packages(c("shiny", "RSQLite", "httr", "jsonlite", "here", "DT"))`.

## Configuration

Set your OpenAI API key in `.Renviron` (`OPENAI_API_KEY=your_api_key_here`) or `config.yml`:

```yaml
default:
  OPENAI_API_KEY: "your_api_key_here"
```

## Usage

1. Open data_team.Rproj in RStudio.
2. Launch the app via shiny::runApp().
3. Input natural language questions for database interaction.

## Structure
- `api_helpers.R`: Manages API requests.
- `server.R`: Handles server-side logic.
- `ui.R`: Defines the UI.
- `Chinook_Sqlite.sqlite`: Contains the chinook music store dataset.
- `my_database.sqlite`: Contains nycflights13 dataset. (not currently in use)
