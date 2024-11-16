#!/usr/bin/python3

class Assignment:
    """
    Class to represent an individual assignments 
    """

    def __init__(self, name, assign_type, score, weight):
        self.name = name
        self.assign_type = assign_type
        # FA for formative, SA for summative
        self.score = float(score)
        self.weight = float(weight)

    def get_weighted_score(self):
        """Calculate the weighted score for this assignment"""
        return (self.score * self.weight) / 100

    def __str__(self):
        """String representation for transcript display"""
        return f"{self.name:<15} {self.assign_type:<15} {self.score:<10.1f} {self.weight:<10.1f}"


class GradeCalculator:
    """
    Class to manage assignments and calculate grades of students
    """

    def __init__(self):
        self.formative_assignments = []
        self.summative_assignments = []
        self.current_formative_weight = 0
        self.current_summative_weight = 0

    def add_assignment(self, name, assign_type, score, weight):
        """Add a new assignment with weight validation"""
        if assign_type == 'FA':
            if self.current_formative_weight + weight <= 60:
                self.formative_assignments.append(Assignment(name, assign_type, score, weight))
                self.current_formative_weight += weight
                return True
        elif assign_type == 'SA':
            if self.current_summative_weight + weight <= 40:
                self.summative_assignments.append(Assignment(name, assign_type, score, weight))
                self.current_summative_weight += weight
                return True
        return False

    def calculate_weighted_score(self, assignments):
        """Calculate total weighted score for a group of assignments"""
        if not assignments:
            return 0
        return sum((assignment.get_weighted_score() for assignment in assignments))

    def check_progression(self):
        """Check if student has passed based on thresholds"""
        formative_total = self.calculate_weighted_score(self.formative_assignments)
        summative_total = self.calculate_weighted_score(self.summative_assignments)

        passed = formative_total >= 30 and summative_total >= 20
        message = (f"\nFormative Total: {formative_total:.1f}%\n"
                   f"Summative Total: {summative_total:.1f}%\n"
                   f"Status: {'Passed! Congratulations!' if passed else 'Failed. You need to retake the course.'}")
        return message

    def check_resubmission(self):
        """Check for assignments eligible for resubmission"""
        low_score_assignments = [a for a in self.formative_assignments if a.score < 50]
        if not low_score_assignments:
            return "\nNo assignments eligible for resubmission."

        message = "\nAssignments eligible for resubmission:"
        for assignment in low_score_assignments:
            message += f"\n{assignment.name} with a score of {assignment.score:.1f}%"
        return message

    def generate_transcript(self, ascending=True):
        """Generate a formatted transcript of all assignments"""
        all_assignments = self.formative_assignments + self.summative_assignments
        sorted_assignments = sorted(all_assignments, key=lambda x: x.score, reverse=not ascending)

        header = "\nTranscript Breakdown ({} Order):".format("Ascending" if ascending else "Descending")
        header += "\nAssignment      Type           Score(%)    Weight (%)"
        header += "\n" + "-" * 59

        transcript = [str(assignment) for assignment in sorted_assignments]
        return "\n".join([header] + transcript + ["-" * 59])


def main():
    """Main function to run the grade calculator"""
    calculator = GradeCalculator()

    print("Welcome to the Grade Calculator!")
    print("Enter your assignments (type 'done' when finished)")

    while True:
        name = input("\nEnter assignment name (or 'done' to finish): ")
        if name.lower() == 'done':
            break

        assign_type = input("Enter type (FA/SA): ").upper()
        while assign_type not in ['FA', 'SA']:
            print("Invalid type. Please enter FA for Formative or SA for Summative.")
            assign_type = input("Enter type (FA/SA): ").upper()

        try:
            score = float(input("Enter score (0-100): "))
            weight = float(input("Enter weight: "))

            if not calculator.add_assignment(name, assign_type, score, weight):
                print("Error: Weight limit exceeded. Maximum is 60% for FA and 40% for SA.")
        except ValueError:
            print("Invalid input. Please enter numeric values for score and weight.")
            continue

    # Display results
    print("\n" + "=" * 50)
    print(calculator.check_progression())
    print(calculator.check_resubmission())

    # Ask for transcript order the student want
    order = input("\nDisplay transcript in ascending or descending order? (a/d): ").lower()
    print(calculator.generate_transcript(ascending=(order == 'a')))


if __name__ == "__main__":
    main()
