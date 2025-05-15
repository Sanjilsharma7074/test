#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    whiptail --msgbox "This script must be run as root." 10 50
    exit 1
fi

# Data storage paths
STUDENTS_FILE="students.txt"
COURSES_FILE="courses.txt"
ENROLLMENTS_FILE="enrollments.txt"
LOG_FILE="/var/log/student_management.log"

# Ensure log file exists
touch "$LOG_FILE"

# Logger function
log_action() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Banner
head_banner() {
    whiptail --title "Student Management System" \
    --msgbox "Welcome to the Student Management System" 10 60
}

# Create Semester
create_semester() {
    SEMESTER=$(whiptail --inputbox "Enter semester name (e.g., Fall2025):" 10 50 3>&1 1>&2 2>&3)
    if [[ "$SEMESTER" =~ ^[A-Za-z0-9]+$ ]]; then
        echo "Semester: $SEMESTER" >> semesters.txt
        log_action "Created semester $SEMESTER"
        whiptail --msgbox "Semester '$SEMESTER' created." 8 40
    else
        whiptail --msgbox "Invalid semester name." 8 40
    fi
}

# Create User
create_user() {
    NAME=$(whiptail --inputbox "Enter student name:" 10 50 3>&1 1>&2 2>&3)
    ID=$(whiptail --inputbox "Enter student ID:" 10 50 3>&1 1>&2 2>&3)

    if [[ "$NAME" =~ ^[A-Za-z\ ]+$ && "$ID" =~ ^[0-9]+$ ]]; then
        echo "$ID:$NAME" >> "$STUDENTS_FILE"
        log_action "Created student $NAME ($ID)"
        whiptail --msgbox "User $NAME created." 8 40
    else
        whiptail --msgbox "Invalid name or ID." 8 40
    fi
}

# Create Course
create_course() {
    COURSE_NAME=$(whiptail --inputbox "Enter course name:" 10 50 3>&1 1>&2 2>&3)
    COURSE_ID=$(whiptail --inputbox "Enter course ID:" 10 50 3>&1 1>&2 2>&3)

    if [[ "$COURSE_NAME" =~ ^[A-Za-z0-9\ ]+$ && "$COURSE_ID" =~ ^[A-Za-z0-9]+$ ]]; then
        echo "$COURSE_ID:$COURSE_NAME" >> "$COURSES_FILE"
        log_action "Created course $COURSE_NAME ($COURSE_ID)"
        whiptail --msgbox "Course $COURSE_NAME created." 8 40
    else
        whiptail --msgbox "Invalid course details." 8 40
    fi
}

# Enroll Student
enroll_student() {
    STUDENT_ID=$(whiptail --inputbox "Enter student ID to enroll:" 10 50 3>&1 1>&2 2>&3)
    COURSE_ID=$(whiptail --inputbox "Enter course ID:" 10 50 3>&1 1>&2 2>&3)

    if grep -q "^$STUDENT_ID:" "$STUDENTS_FILE" && grep -q "^$COURSE_ID:" "$COURSES_FILE"; then
        echo "$STUDENT_ID:$COURSE_ID" >> "$ENROLLMENTS_FILE"
        log_action "Enrolled student $STUDENT_ID to course $COURSE_ID"
        whiptail --msgbox "Enrolled student $STUDENT_ID in course $COURSE_ID." 8 50
    else
        whiptail --msgbox "Invalid student ID or course ID." 8 40
    fi
}

# View All Courses
view_courses() {
    if [[ -s "$COURSES_FILE" ]]; then
        whiptail --textbox "$COURSES_FILE" 20 60
    else
        whiptail --msgbox "No courses found." 8 40
    fi
}

# View Enrollments
view_enrollments() {
    if [[ -s "$ENROLLMENTS_FILE" ]]; then
        OUTPUT=""
        while IFS=: read -r SID CID; do
            STUDENT_NAME=$(grep "^$SID:" "$STUDENTS_FILE" | cut -d: -f2)
            COURSE_NAME=$(grep "^$CID:" "$COURSES_FILE" | cut -d: -f2)
            OUTPUT+="Student: $STUDENT_NAME ($SID) - Course: $COURSE_NAME ($CID)\n"
        done < "$ENROLLMENTS_FILE"
        echo -e "$OUTPUT" > temp_enrollments.txt
        whiptail --textbox temp_enrollments.txt 20 60
        rm temp_enrollments.txt
    else
        whiptail --msgbox "No enrollments found." 8 40
    fi
}

# Modify Course Teacher (Placeholder)
modify_teacher() {
    whiptail --msgbox "Modify teacher feature not implemented yet." 8 40
}

# Delete Student
delete_student() {
    STUDENT_ID=$(whiptail --inputbox "Enter Student ID to delete:" 10 50 3>&1 1>&2 2>&3)

    if grep -q "^$STUDENT_ID:" "$STUDENTS_FILE"; then
        whiptail --yesno "Are you sure you want to delete student ID $STUDENT_ID?" 8 50
        if [[ $? -eq 0 ]]; then
            grep -v "^$STUDENT_ID:" "$STUDENTS_FILE" > temp && mv temp "$STUDENTS_FILE"
            grep -v "^$STUDENT_ID:" "$ENROLLMENTS_FILE" > temp && mv temp "$ENROLLMENTS_FILE"
            log_action "Deleted student $STUDENT_ID"
            whiptail --msgbox "Student $STUDENT_ID deleted." 8 40
        fi
    else
        whiptail --msgbox "Student ID not found." 8 40
    fi
}

# View All Students
view_students() {
    if [[ -s "$STUDENTS_FILE" ]]; then
        whiptail --textbox "$STUDENTS_FILE" 20 60
    else
        whiptail --msgbox "No student records found." 8 40
    fi
}

# Search Student
search_student() {
    QUERY=$(whiptail --inputbox "Enter student name or ID to search:" 10 50 3>&1 1>&2 2>&3)
    grep -i "$QUERY" "$STUDENTS_FILE" > temp_result.txt
    if [[ -s temp_result.txt ]]; then
        whiptail --textbox temp_result.txt 15 60
    else
        whiptail --msgbox "No matching records found." 8 40
    fi
    rm -f temp_result.txt
}

# Main Menu
main_menu() {
    while true; do
        OPTION=$(whiptail --title "Student Management System" --menu "Choose an option:" 20 60 12 \
        "1" "Create Semester" \
        "2" "Create User" \
        "3" "Create Course" \
        "4" "Enroll Student in Course" \
        "5" "View Courses" \
        "6" "View Course Enrollments" \
        "7" "Modify Course Teacher" \
        "8" "Delete Student" \
        "9" "View Students (Admin)" \
        "10" "Search Student" \
        "11" "Exit" 3>&1 1>&2 2>&3)

        case $OPTION in
            1) create_semester ;;
            2) create_user ;;
            3) create_course ;;
            4) enroll_student ;;
            5) view_courses ;;
            6) view_enrollments ;;
            7) modify_teacher ;;
            8) delete_student ;;
            9) view_students ;;
            10) search_student ;;
            11) break ;;
            *) whiptail --msgbox "Invalid option." 8 40 ;;
        esac
    done
}

# Run script
head_banner
main_menu
