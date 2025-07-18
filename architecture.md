# الحضور المريح - Worker Attendance Evaluation App Architecture

## App Overview
A Flutter app for evaluating worker attendance on a monthly basis with Arabic language support.

## Core Features (MVP)
1. **Worker Management**
   - Add/edit/delete workers
   - Worker profiles with basic info (name, ID, department, position)

2. **Daily Attendance Tracking**
   - Mark attendance status (Present, Absent, Late, Excused)
   - Date-based attendance recording
   - Quick attendance marking interface

3. **Monthly Attendance Evaluation**
   - Monthly attendance summaries
   - Attendance percentage calculations
   - Generate monthly reports

4. **Attendance History**
   - View past attendance records
   - Filter by date range and worker
   - Search functionality

## Technical Implementation Plan

### Data Models
1. **Worker Model** (`lib/models/worker.dart`)
   - id, name, employeeId, department, position, phoneNumber

2. **Attendance Model** (`lib/models/attendance.dart`)
   - id, workerId, date, status, notes, timestamp

3. **Monthly Report Model** (`lib/models/monthly_report.dart`)
   - workerId, month, year, totalDays, presentDays, percentage

### Core Services
1. **Local Storage Service** (`lib/services/storage_service.dart`)
   - Using shared_preferences for data persistence
   - CRUD operations for workers and attendance

2. **Attendance Service** (`lib/services/attendance_service.dart`)
   - Business logic for attendance management
   - Monthly report generation

### Screen Structure
1. **Home Screen** (`lib/screens/home_screen.dart`)
   - Dashboard with quick stats
   - Navigation to main features

2. **Workers Screen** (`lib/screens/workers_screen.dart`)
   - List of all workers
   - Add/edit worker functionality

3. **Daily Attendance Screen** (`lib/screens/daily_attendance_screen.dart`)
   - Mark attendance for all workers
   - Date selection

4. **Monthly Reports Screen** (`lib/screens/monthly_reports_screen.dart`)
   - Generate and view monthly reports
   - Filter by month/year

5. **Attendance History Screen** (`lib/screens/attendance_history_screen.dart`)
   - View detailed attendance history
   - Search and filter options

### UI Components
1. **Worker Card** (`lib/widgets/worker_card.dart`)
2. **Attendance Status Badge** (`lib/widgets/attendance_badge.dart`)
3. **Monthly Summary Card** (`lib/widgets/monthly_summary_card.dart`)
4. **Date Picker Widget** (`lib/widgets/date_picker_widget.dart`)

### Dependencies Required
- shared_preferences: ^2.2.2 (for local storage)
- intl: ^0.19.0 (for date formatting and Arabic support)

## Implementation Steps
1. Create data models and enums
2. Implement local storage service
3. Create attendance service with business logic
4. Implement home screen with navigation
5. Create worker management screens
6. Implement daily attendance tracking
7. Create monthly reports functionality
8. Add attendance history and search
9. Add sample data and testing
10. Final testing and bug fixes

## Arabic Language Support
- RTL layout support
- Arabic text rendering
- Date formatting in Arabic
- Proper Arabic typography using Google Fonts

## Color Scheme
The existing purple-based theme is professional and suitable for a business attendance app.