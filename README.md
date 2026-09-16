# SmartDroneDelivery — Database Design Report

This repository contains the LaTeX source for the **SmartDroneDelivery Database Design** report, submitted as a course assignment for the *Database Search and Design* subject at the University of Technology (UT), Ho Chi Minh City.

The report focuses exclusively on the **database design** of an AI-powered Drone Delivery Management Platform. It covers data requirements analysis, conceptual modeling (ERD), logical relational schema, normalization, physical PostgreSQL implementation, and database testing.

## Project Information

| Field | Detail |
|---|---|
| **Project name** | SmartDroneDelivery — AI-powered Drone Delivery Management Platform |
| **Subject** | Database Search and Design (Tìm kiếm cơ sở dữ liệu) |
| **Group** | Group 4 |
| **Members** | 089206011070 – Tran Tan Phat |
| | 079206000967 – Tran Hoang Son |
| | 056206000983 – Nguyen Duy Quy |
| | 054206007389 – Nguyen Quoc Dung |
| | 079206004792 – Le Huy Hoang |

## Report Structure

| Chapter | Title | Description |
|---|---|---|
| 1 | Introduction | Project background, database perspective, scope |
| 2 | Database Requirements Analysis | Actors, functional requirements, business rules, data requirements, requirement-to-entity traceability |
| 3 | Database Design | Conceptual model (ERD), logical relational schema, normalization (1NF–3NF), integrity constraints, physical PostgreSQL implementation (21 tables), index strategy |
| 4 | Database Testing and Evaluation | PK/FK/UNIQUE/CHECK tests, business rule tests, history tests, failed delivery test, query tests, performance tests |
| 5 | Conclusion | Design results, limitations, future improvements |

## Database Schema Overview

The final schema consists of **21 tables** organized into six groups:

- **User & Authorization**: `system_user`, `role`, `permission`, `user_role`, `role_permission`
- **Customer**: `customer`, `customer_address`
- **Delivery Order**: `delivery_order`, `package`, `order_status_history`
- **Delivery Execution**: `drone`, `landing_station`, `delivery_activity`, `tracking_record`, `delivery_confirmation`, `delivery_exception`, `station_status_history`
- **Audit**: `audit_log`
- **Optional**: `delivery_route`, `route_point`, `ai_recommendation`

The core design pattern is:

```
delivery_order
    └── delivery_activity ── drone
            ├── tracking_record
            └── delivery_exception
```

This pattern replaces the incorrect direct 1:1 relationship between an order and a drone, allowing multiple delivery attempts per order and full history tracking per attempt.

## Technology

- **Database**: PostgreSQL
- **Document**: LaTeX (pdfTeX / TeX Live 2025)
- **Key PostgreSQL features used**: `BIGINT GENERATED ALWAYS AS IDENTITY`, `TIMESTAMPTZ`, `JSONB`, `INET`, `CHECK` constraints, `FOREIGN KEY` with referential actions, composite indexes

## Usage

1. Clone or download this repository.
2. Open `book.tex` in your LaTeX editor.
3. Compile with `pdflatex` (run twice to resolve cross-references):

```bash
pdflatex book.tex
pdflatex book.tex
```

The compiled output is `book.pdf`.

> **Required files** (do not modify or move):
> - `book.sty` — LaTeX style file
> - `book.bst` — BibTeX bibliography style

## Software

- Tested with **TeX Live 2025** on Windows.
- Compatible with pdfLaTeX, XeLaTeX, and LuaLaTeX (font settings may differ for non-pdfTeX engines).

## License

The LaTeX template structure is based on [latex-book](https://github.com/pmichaillat/latex-book) by P. Michaillat, licensed under the [MIT License](LICENSE.md). The report content is the original work of Group 4.
