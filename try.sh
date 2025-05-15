#!/bin/bash

# Ensure script runs as root
if [[ "$EUID" -ne 0 ]]; then
    whiptail --msgbox "This script must be run as root." 8 50
    exit 1
fi

# Data storage paths
STUDENTS_FILE="students.txt"
COURSES_FILE="courses.txt"
ENROLLMENTS_FILE="enrollments.txt"
LOG_FILE="/var/log/student_mgmt.log"

# Logger function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Banner
head_banner() {
    whiptail --title "Student Management System" \
    --msgbox "Welcome to the Student Management System" 10 60
}

# Create a semester
create_semester() {
    SEMESTER=$(whiptail --inputbox "Enter semester name (e.g., Fall2025):" 10 50 3>&1 1>&2 2>&3)
    if [[ -n "$SEMESTER" ]]; then
        echo "Semester: $SEMESTER created!" >> semesters.txt
        log_action "Created semester: $SEMESTER"
        whiptail --msgbox "Semester '$SEMESTER' created." 8 40
    else
        whiptail --msgbox "No semester name provided." 8 40
    fi
}

# Create a user (student)
create_user() {
    NAME=$(whiptail --inputbox "Enter student name:" 10 50 3>&1 1>&2 2>&3)
    ID=$(whiptail --inputbox "Enter student ID:" 10 50 3>&1 1>&2 2>&3)

    if [[ -n "$NAME" && -n "$ID" ]]; then
        echo "$ID:$NAME" >> "$STUDENTS_FILE"
        useradd -m "$ID" && echo "$ID:password" | chpasswd
        log_action "Created student: $NAME ($ID) and system user."
        whiptail --msgbox "User $NAME created and system user '$ID' added with default password 'password'." 10 60
    else
        whiptail --msgbox "Missing name or ID." 8 40
    fi
}

# Modify student information
modify_student() {
    ID=$(whiptail --inputbox "Enter student ID to modify:" 10 50 3>&1 1>&2 2>&3)
    if grep -q "^$ID:" "$STUDENTS_FILE"; then
        NEW_NAME=$(whiptail --inputbox "Enter new name for student $ID:" 10 50 3>&1 1>&2 2>&3)
        sed -i "s/^$ID:.*/$ID:$NEW_NAME/" "$STUDENTS_FILE"
        log_action "Modified student $ID to new name: $NEW_NAME"
        whiptail --msgbox "Student $ID name updated." 8 40
    else
        whiptail --msgbox "Student ID not found." 8 40
    fi
}

# Create a course
create_course() {
    COURSE_NAME=$(whiptail --inputbox "Enter course name:" 10 50 3>&1 1>&2 2>&3)
    COURSE_ID=$(whiptail --inputbox "Enter course ID:" 10 50 3>&1 1>&2 2>&3)
    if [[ -n "$COURSE_NAME" && -n "$COURSE_ID" ]]; then
        echo "$COURSE_ID:$COURSE_NAME" >> "$COURSES_FILE"
        log_action "Created course: $COURSE_NAME ($COURSE_ID)"
        whiptail --msgbox "Course $COURSE_NAME created." 8 40
    else
        whiptail --msgbox "Missing course details." 8 40
    fi
}

# Enroll student in course
enroll_student() {
    STUDENT_ID=$(whiptail --inputbox "Enter student ID to enroll:" 10 50 3>&1 1>&2 2>&3)
    COURSE_ID=$(whiptail --inputbox "Enter course ID:" 10 50 3>&1 1>&2 2>&3)
    if [[ -n "$STUDENT_ID" && -n "$COURSE_ID" ]]; then
        echo "$STUDENT_ID:$COURSE_ID" >> "$ENROLLMENTS_FILE"
        log_action "Enrolled student $STUDENT_ID in course $COURSE_ID"
        whiptail --msgbox "Enrolled student $STUDENT_ID to course $COURSE_ID." 8 50
    else
        whiptail --msgbox "Missing student ID or course ID." 8 40
    fi
}

# View all courses
view_courses() {
    if [[ -s "$COURSES_FILE" ]]; then
        whiptail --textbox "$COURSES_FILE" 20 60
    else
        whiptail --msgbox "No courses found." 8 40
    fi
}

# View course enrollments
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

# Delete student
delete_student() {
    STUDENT_ID=$(whiptail --inputbox "Enter Student ID to delete:" 10 50 3>&1 1>&2 2>&3)
    if grep -q "^$STUDENT_ID:" "$STUDENTS_FILE"; then
        userdel -r "$STUDENT_ID" 2>/dev/null
        grep -v "^$STUDENT_ID:" "$STUDENTS_FILE" > temp && mv temp "$STUDENTS_FILE"
        grep -v "^$STUDENT_ID:" "$ENROLLMENTS_FILE" > temp && mv temp "$ENROLLMENTS_FILE"
        log_action "Deleted student $STUDENT_ID and system user."
        whiptail --msgbox "Student $STUDENT_ID deleted." 8 40
    else
        whiptail --msgbox "Student ID not found." 8 40
    fi
}

# View all students
view_students() {
    if [[ -s "$STUDENTS_FILE" ]]; then
        whiptail --textbox "$STUDENTS_FILE" 20 60
    else
        whiptail --msgbox "No student records found." 8 40
    fi
}

# Search for a student
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

# Modify course teacher (not implemented)
modify_teacher() {
    whiptail --msgbox "This feature is not implemented yet." 8 40
}

# Main menu
main_menu() {
    while true; do
        OPTION=$(whiptail --title "Student Management System" --menu "Choose an option:" 20 60 12 \
        "1" "Create Semester" \
        "2" "Create User" \
        "3" "Modify User Info" \
        "4" "Create Course" \
        "5" "Enroll Student in Course" \
        "6" "View Courses" \
        "7" "View Course Enrollments" \
        "8" "Modify Course Teacher" \
        "9" "Delete Student" \
        "10" "View Students (Admin)" \
        "11" "Search Student" \
        "12" "Exit" 3>&1 1>&2 2>&3)

        case $OPTION in
            1) create_semester ;;
            2) create_user ;;
            3) modify_student ;;
            4) create_course ;;
            5) enroll_student ;;
            6) view_courses ;;
            7) view_enrollments ;;
            8) modify_teacher ;;
            9) delete_student ;;
            10) view_students ;;
            11) search_student ;;
            12) break ;;
            *) whiptail --msgbox "Invalid option." 8 40 ;;
        esac
    done
}

# Run script
head_banner
main_menu
