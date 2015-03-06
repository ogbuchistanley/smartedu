SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

DELIMITER $$
CREATE PROCEDURE `proc_annualClassPositionViews`(IN `ClassID` INT, IN `AcademicYearID` INT)
  BEGIN
-- Create a Temporary Table to Hold The Values
    DROP TEMPORARY TABLE IF EXISTS AnnualClassPositionResultTable;
    CREATE TEMPORARY TABLE IF NOT EXISTS AnnualClassPositionResultTable
    (
-- Add the column definitions for the TABLE variable here
      row_id int AUTO_INCREMENT,
      student_id INT,
      full_name VARCHAR(100),
      class_id INT,
      class_name VARCHAR(50),
      academic_year_id int,
      academic_year varchar(80),
      student_annual_total_score Decimal(6, 2),
      exam_annual_perfect_score Decimal(6, 2),
      class_annual_position int,
      clas_size int, PRIMARY KEY (row_id)
    );

-- cursor block for calculating the students annual exam total scores
      Block1: BEGIN
      DECLARE done1 BOOLEAN DEFAULT FALSE;
      DECLARE StudentID, ClassRoomID, YearID INT;
      DECLARE StudentName VARCHAR(150);
      DECLARE ClassName, YearName VARCHAR(50);
      DECLARE cur1 CURSOR FOR SELECT student_id, student_name, class_id, class_name, academic_year_id,academic_year
                              FROM students_classlevelviews WHERE class_id=ClassID AND academic_year_id=AcademicYearID
                              GROUP BY student_id, student_name, class_id, class_name, academic_year_id,academic_year;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;

-- Open The Cursor For Iterating Through The Recordset cur1
      OPEN cur1;
      REPEAT
        FETCH cur1 INTO StudentID, StudentName, ClassRoomID, ClassName, YearID, YearName;
        IF NOT done1 THEN
          BEGIN
--  Call to the records
            SET @Res = (SELECT func_annualExamsViews(StudentID, AcademicYearID));

            IF @Res > 0 THEN
              BEGIN
                INSERT INTO AnnualClassPositionResultTable(student_id, full_name, class_id, class_name, academic_year_id, academic_year, student_annual_total_score, exam_annual_perfect_score)
                  SELECT StudentID, StudentName, ClassRoomID, ClassName, YearID, YearName, CAST(SUM(annual_average) AS Decimal(6, 2)), (COUNT(annual_average) * 100)
                  FROM AnnualSubjectViewsResultTable;
              END;
            END IF;
          END;
        END IF;
      UNTIL done1 END REPEAT;
      CLOSE cur1;
    END Block1;

-- cursor block for calculating the students annual class Position
      Block2: BEGIN
-- Get the number of students in the class
      SET @ClassSize = (SELECT COUNT(*) FROM students_classlevelviews
      WHERE class_id = ClassID AND academic_year_id = AcademicYearID
      );
      SET @TempPosition = 1;
      SET @TempStudentScore = 0;
      SET @Position = 0;

        Block3: BEGIN
        DECLARE done2 BOOLEAN DEFAULT FALSE;
        DECLARE RowID INT;
        DECLARE StudentAnnualTotal Decimal(6, 2);
        DECLARE cur2 CURSOR FOR SELECT row_id, student_annual_total_score
                                FROM AnnualClassPositionResultTable WHERE class_id=ClassID AND academic_year_id=AcademicYearID
                                GROUP BY row_id, student_annual_total_score
                                ORDER BY student_annual_total_score DESC;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done2 = TRUE;

-- Open The Cursor For Iterating Through The Recordset cur1
        OPEN cur2;
        REPEAT
          FETCH cur2 INTO RowID, StudentAnnualTotal;
          IF NOT done2 THEN
            BEGIN
-- IF the current student total is equal to the next student's total
              IF @TempStudentScore = StudentAnnualTotal THEN
-- Add one to the temp variable position
                SET @TempPosition = @TempPosition + 1;
-- Else if they are not equal
              ELSE
                BEGIN
-- Set the current student's position to be that of the temp variable
                  SET @Position = @TempPosition;
-- Add one to the temp variable position
                  SET @TempPosition = @TempPosition + 1;
                END;
              END IF;
              BEGIN
-- update the resultant table that will display the computed class position results
                UPDATE AnnualClassPositionResultTable SET class_annual_position=@Position, clas_size=@ClassSize
                WHERE row_id=RowID;
              END;
-- Get the current student total score and set it the variable for the next comparism
              SET @TempStudentScore = StudentAnnualTotal;
            END;
          END IF;
        UNTIL done2 END REPEAT;
        CLOSE cur2;
      END Block3;
    END Block2;
  END$$

CREATE PROCEDURE `proc_assignSubject2Students`(IN `subjectClasslevelID` INT)
  BEGIN
    SELECT classlevel_id, class_id, academic_term_id
    INTO @ClassLevelID, @ClassID, @AcademicTermID
    FROM subject_classlevels WHERE subject_classlevel_id=subjectClasslevelID LIMIT 1;
    SET @SubjectClasslevelID = subjectClasslevelID;


    SELECT COUNT(*) INTO @Exist FROM subject_students_registers WHERE subject_classlevel_id=subjectClasslevelID LIMIT 1;
    IF @Exist > 0 THEN
      BEGIN
        DELETE FROM subject_students_registers WHERE subject_classlevel_id=subjectClasslevelID;
      END;
    END IF;


    IF @ClassID IS NULL THEN
      BEGIN
        INSERT INTO subject_students_registers(student_id, class_id, subject_classlevel_id)
          SELECT	b.student_id, b.class_id, @SubjectClasslevelID
          FROM	students a INNER JOIN students_classes b ON a.student_id=b.student_id INNER JOIN
            classrooms c ON c.class_id = b.class_id
          WHERE 	c.classlevel_id = @ClassLevelID  AND a.student_status_id = 1
                 AND 	b.academic_year_id = (SELECT academic_year_id FROM academic_terms WHERE academic_term_id = @AcademicTermID LIMIT 1);
      END;
    ELSE
      BEGIN
        INSERT INTO subject_students_registers(student_id, class_id, subject_classlevel_id)
          SELECT	b.student_id, b.class_id, @SubjectClasslevelID
          FROM	students a INNER JOIN students_classes b ON a.student_id=b.student_id INNER JOIN
            classrooms c ON c.class_id = b.class_id
          WHERE	b.class_id = @ClassID AND a.student_status_id = 1
                 AND 	b.academic_year_id = (SELECT academic_year_id FROM academic_terms WHERE academic_term_id = @AcademicTermID LIMIT 1);
      END;
    END IF;

  END$$

CREATE PROCEDURE `proc_examsDetailsReportViews`(IN `AcademicID` INT, IN `TypeID` INT)
  BEGIN
-- Create Temporary Table
    DROP TEMPORARY TABLE IF EXISTS ExamsDetailsResultTable;
    CREATE TEMPORARY TABLE IF NOT EXISTS ExamsDetailsResultTable
    (
-- Add the column definitions for the TABLE variable here
      row_id int AUTO_INCREMENT, exam_id int, subject_id int, classlevel_id int, class_id int, student_id int,
      subject_name varchar(80), class_name varchar(80), student_fullname varchar(180),
      ca1 int, ca2 int, exam int, weightageCA1 int, weightageCA2 int, weightageExam int,
      academic_term_id int, academic_term varchar(80), exammarked_status_id int, academic_year_id int,
      academic_year varchar(80), classlevel varchar(80), classgroup_id int,
      studentSubjectTotal Decimal(6, 2), studentPercentTotal Decimal(6, 2), weightageTotal Decimal(6, 2), grade varchar(20),
      grade_abbr varchar(5), student_sum_total Decimal(6, 2), exam_perfect_score int, PRIMARY KEY (row_id)
    );

-- TypeID values 1 for term while others for year
    IF TypeID = 1 THEN
-- Insert Into the temporary table
      INSERT INTO ExamsDetailsResultTable(exam_id, subject_id, classlevel_id, class_id, student_id,
                                          subject_name, class_name, student_fullname,
                                          ca1, ca2, exam, weightageCA1, weightageCA2, weightageExam,
                                          academic_term_id, academic_term, exammarked_status_id, academic_year_id,
                                          academic_year, classlevel, classgroup_id)
        SELECT * FROM examsdetails_reportviews
        WHERE exammarked_status_id=1 AND academic_term_id=AcademicID;
    ELSE
-- Insert Into the temporary table
      INSERT INTO ExamsDetailsResultTable(exam_id, subject_id, classlevel_id, class_id, student_id,
                                          subject_name, class_name, student_fullname,
                                          ca1, ca2, exam, weightageCA1, weightageCA2, weightageExam,
                                          academic_term_id, academic_term, exammarked_status_id, academic_year_id,
                                          academic_year, classlevel, classgroup_id)
        SELECT * FROM examsdetails_reportviews
        WHERE exammarked_status_id=1 AND academic_term_id IN
                                         (SELECT academic_term_id FROM academic_terms WHERE academic_year_id=AcademicID);
    END IF;
-- cursor block for calculating the students exam total scores
      Block1: BEGIN
      DECLARE done1 BOOLEAN DEFAULT FALSE;
      DECLARE RowID, StudentID, SubjectID, TermID INT;
      DECLARE cur1 CURSOR FOR SELECT row_id, student_id, subject_id, academic_term_id
                              FROM ExamsDetailsResultTable;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;

-- Open The Cursor For Iterating Through The Recordset cur1
      OPEN cur1;
      REPEAT
        FETCH cur1 INTO RowID, StudentID, SubjectID, TermID;
        IF NOT done1 THEN
          BEGIN
            SELECT CAST((ca1 + ca2 + exam) AS Decimal(6, 2)), CAST((((ca1 + ca2 + exam) / (weightageCA1 + weightageCA2 + weightageExam)) * 100)
                                                                   AS Decimal(6, 2)), CAST((weightageCA1 + weightageCA2 + weightageExam) AS Decimal(6, 2)) INTO @StudentSubjectTotal,  @StudentPercentTotal, @WeightageTotal
            FROM exam_details INNER JOIN exams ON exam_details.exam_id = exams.exam_id INNER JOIN
              subject_classlevels ON exams.subject_classlevel_id = subject_classlevels.subject_classlevel_id
            WHERE  exam_details.student_id = StudentID AND subject_id=SubjectID AND subject_classlevels.academic_term_id = TermID
            GROUP BY exam_details.student_id;
-- update the temporary table with the new calculated values
            BEGIN
              UPDATE ExamsDetailsResultTable SET
                studentSubjectTotal=@StudentSubjectTotal, studentPercentTotal=@StudentPercentTotal, weightageTotal=@WeightageTotal
              WHERE row_id=RowID AND student_id = StudentID AND subject_id=SubjectID AND academic_term_id = TermID;
            END;
          END;
        END IF;
      UNTIL done1 END REPEAT;
      CLOSE cur1;
    END Block1;

-- cursor for calculating the students grade base on the scores
      Block2: BEGIN
      DECLARE done2 BOOLEAN DEFAULT FALSE;
      DECLARE RowID, StudentID, SubjectID, TermID, ClassGroupID INT;
      DECLARE StudentPercentT Decimal(6, 2);
      DECLARE cur2 CURSOR FOR SELECT row_id, student_id, subject_id, academic_term_id, studentPercentTotal, classgroup_id
                              FROM ExamsDetailsResultTable;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET done2 = TRUE;

-- Open The Cursor For Iterating Through The Recordset cur1
      OPEN cur2;
      REPEAT
        FETCH cur2 INTO RowID, StudentID, SubjectID, TermID, StudentPercentT, ClassGroupID;
        IF NOT done2 THEN
          BEGIN
            SELECT grade, grade_abbr INTO @Grade, @GradeAbbr FROM grades
            WHERE StudentPercentT BETWEEN lower_bound AND upper_bound AND classgroup_id = ClassGroupID;

            SELECT CAST(SUM(studentPercentTotal)AS Decimal(6, 2)), (COUNT(studentPercentTotal) * 100) INTO @StudentSumTotal, @ExamPerfectScore
            FROM ExamsDetailsResultTable WHERE student_id = StudentID AND academic_term_id = TermID GROUP BY student_id;
-- update the temporary table with the calculated values
            BEGIN
              UPDATE ExamsDetailsResultTable SET grade=@Grade, grade_abbr=@GradeAbbr,
                student_sum_total=@StudentSumTotal, exam_perfect_score=@ExamPerfectScore
              WHERE row_id=RowID AND student_id = StudentID AND subject_id=SubjectID AND academic_term_id = TermID;
            END;
          END;
        END IF;
      UNTIL done2 END REPEAT;
      CLOSE cur2;
    END Block2;
  END$$

CREATE PROCEDURE `proc_insertAttendDetails`(IN `AttendID` INT, `StudentIDS` VARCHAR(225))
  BEGIN
--  Delete The Record if it exists
    SELECT COUNT(*) INTO @Exist FROM attend_details WHERE attend_id=AttendID;
    IF @Exist > 0 THEN
      BEGIN
        DELETE FROM attend_details WHERE attend_id=AttendID;
      END;
    END IF;

    IF StudentIDS IS NOT NULL THEN
      BEGIN
        DECLARE count INT Default 0 ;
        DECLARE student_id VARCHAR(255);
        simple_loop: LOOP
          SET count = count + 1;
          SET student_id = SPLIT_STR(StudentIDS, ',', count);
          IF student_id = '' THEN
            LEAVE simple_loop;
          END IF;
--  Insert into the attend details table those present
          INSERT INTO attend_details(attend_id, student_id)
            SELECT AttendID, student_id;
        END LOOP simple_loop;
      END;
    END IF;
  END$$

CREATE PROCEDURE `proc_insertExamDetails`(IN `ExamID` INT)
  BEGIN
    SELECT class_id, subject_classlevel_id
    INTO @ClassID, @SubjectClasslevelID
    FROM exams
    WHERE exam_id=ExamID LIMIT 1;

--  Delete The Record if it exists
    SELECT COUNT(*) INTO @Exist FROM exam_details WHERE exam_id=ExamID;
    IF @Exist > 0 THEN
      BEGIN
        DELETE FROM exam_details WHERE exam_id=ExamID;
      END;
    END IF;

--  Insert into the details table
    BEGIN
      INSERT INTO exam_details(exam_id, student_id)
        SELECT	ExamID, student_id
        FROM	subject_students_registers
        WHERE 	class_id=@ClassID AND subject_classlevel_id=@SubjectClasslevelID;
    END;
  END$$

CREATE PROCEDURE `proc_processItemVariable`(IN `ItemVariableID` INT)
  BEGIN
    SELECT item_id, student_id, class_id, academic_term_id, price
    INTO @ItemID, @StudentID, @ClassID, @AcademicTermID, @Price
    FROM item_variables WHERE item_variable_id = ItemVariableID LIMIT 1;

    SET @SponsorID = (SELECT sponsor_id FROM students WHERE student_id=@StudentID);
    SET @AcademicYearID = (SELECT academic_year_id FROM academic_terms WHERE academic_term_id=@AcademicTermID LIMIT 1);

      Block1: BEGIN
      IF @StudentID IS NOT NULL THEN
        BEGIN
          INSERT INTO orders(student_id, sponsor_id, academic_term_id)
          VALUES (@StudentID, @SponsorID, @AcademicTermID);

          SET @OrderID = (SELECT MAX(order_id) FROM orders LIMIT 1);

          INSERT INTO order_items(order_id, item_id, price)
          VALUES (@OrderID, @ItemID, @Price);
        END;
      ELSE
          Block2: BEGIN
-- Declare Variable to be used in looping through the recordset or cursor
          DECLARE done1 BOOLEAN DEFAULT FALSE;
          DECLARE StudentID, SponsorID INT;

-- Populate the cursor with the values in a record i want to iterate through
          DECLARE cur1 CURSOR FOR
            SELECT student_id, sponsor_id
            FROM students_classlevelviews
            WHERE student_status_id=1 AND class_id=@ClassID AND academic_year_id=@AcademicYearID;

          DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;
-- Open The Cursor For Iterating Through The Recordset cur1
          OPEN cur1;
          REPEAT
            FETCH cur1 INTO StudentID, SponsorID;
            IF NOT done1 THEN
              BEGIN
                INSERT INTO orders(student_id, sponsor_id, academic_term_id)
                  SELECT StudentID, SponsorID, @AcademicTermID;

                SET @OrderID = (SELECT MAX(order_id) FROM orders LIMIT 1);

                INSERT INTO order_items(order_id, item_id, price)
                  SELECT @OrderID, @ItemID, @Price;
              END;
            END IF;
          UNTIL done1 END REPEAT;
          CLOSE cur1;
        END Block2;
      END IF;
    END Block1;
  END$$

CREATE PROCEDURE `proc_processTerminalFees`(IN `ProcessID` INT)
  BEGIN
    SELECT academic_term_id
    INTO @AcademicTermID
    FROM process_items WHERE process_item_id = ProcessID LIMIT 1;
    SET @TermTypeID = (SELECT term_type_id FROM academic_terms WHERE academic_term_id=@AcademicTermID);

      Block1: BEGIN
      INSERT INTO orders(student_id, sponsor_id, academic_term_id, process_item_id)
        SELECT student_id, sponsor_id, @AcademicTermID, ProcessID
        FROM students_classlevelviews WHERE student_status_id=1;

      if @TermTypeID = 1 THEN
        BEGIN
          INSERT INTO order_items(order_id, item_id, price)
            SELECT order_id, item_id, price FROM student_feesqueryviews
            WHERE process_item_id=ProcessID AND item_type_id <> 3 AND item_status_id=1;
        END;
      ELSEIF @TermTypeID = 3 THEN
        BEGIN
          INSERT INTO order_items(order_id, item_id, price)
            SELECT order_id, item_id, price FROM student_feesqueryviews
            WHERE process_item_id=ProcessID AND item_type_id <> 2 AND item_status_id=1;
        END;
      ELSE
        BEGIN
          INSERT INTO order_items(order_id, item_id, price)
            SELECT order_id, item_id, price FROM student_feesqueryviews
            WHERE process_item_id=ProcessID AND item_type_id = 1 AND item_status_id=1;
        END;
      END IF;
    END Block1;
  END$$

CREATE PROCEDURE `proc_terminalClassPositionViews`(IN `cla_id` INT, IN `term_id` INT)
    Block0: BEGIN
    SET @Output = 0;
-- Create a Temporary Table to Hold The Values
    DROP TEMPORARY TABLE IF EXISTS TerminalClassPositionResultTable;
    CREATE TEMPORARY TABLE IF NOT EXISTS TerminalClassPositionResultTable
    (
-- Add the column definitions for the TABLE variable here
      student_id int,
      full_name varchar(80),
      class_id int,
      class_name varchar(50),
      academic_term_id int,
      academic_term varchar(50),
      student_sum_total float,
      exam_perfect_score int,
      class_position int,
      clas_size int
    );

    CALL proc_examsDetailsReportViews(term_id, 1);

      Block1: BEGIN
-- CALL smartschool.proc_examsDetailsReportViews(term_id);
-- Get the number of students in the class
      SET @ClassSize = (SELECT COUNT(*) FROM students_classlevelviews
      WHERE class_id = cla_id AND academic_year_id = (
        SELECT academic_year_id FROM academic_terms WHERE academic_term_id=term_id)
      );
      SET @TempPosition = 1;
      SET @TempStudentScore = 0;
      SET @Position = 0;

        Block2: BEGIN
-- Declare Variable to be used in looping through the recordset or cursor
        DECLARE done1 BOOLEAN DEFAULT FALSE;
        DECLARE StudentID, ClassID, TermID int;
        DECLARE StudentName, ClassName, TermName nvarchar(60);
        DECLARE StudentSumTotal, ExamPerfectScore float;
-- Populate the cursor with the values in a record i want to iterate through

        DECLARE cur1 CURSOR FOR
          SELECT student_id, student_fullname, class_id, class_name, academic_term_id, academic_term, student_sum_total, exam_perfect_score
          FROM ExamsDetailsResultTable WHERE class_id = cla_id and academic_term_id = term_id
          GROUP BY student_id, student_fullname, class_name, academic_term, student_sum_total, exam_perfect_score
          ORDER BY student_sum_total DESC;

        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;
-- Open The Cursor For Iterating Through The Recordset cur1
        OPEN cur1;
        REPEAT
          FETCH cur1 INTO StudentID, StudentName, ClassID, ClassName, TermID, TermName, StudentSumTotal, ExamPerfectScore;
          IF NOT done1 THEN
            BEGIN
-- IF the current student total is equal to the next student's total
              IF @TempStudentScore = StudentSumTotal THEN
-- Add one to the temp variable position
                SET @TempPosition = @TempPosition + 1;
-- Else if they are not equal
              ELSE
                BEGIN
-- Set the current student's position to be that of the temp variable
                  SET @Position = @TempPosition;
-- Add one to the temp variable position
                  SET @TempPosition = @TempPosition + 1;
                END;
              END IF;
              BEGIN
-- Insert into the resultant table that will display the computed results
                INSERT INTO TerminalClassPositionResultTable
                VALUES(StudentID, StudentName, ClassID, ClassName, TermID, TermName, StudentSumTotal, ExamPerfectScore, @Position, @ClassSize);
              END;
-- Get the current student total score and set it the variable for the next comparism
              SET @TempStudentScore = @StudentSumTotal;
            END;
          END IF;
        UNTIL done1 END REPEAT;
        CLOSE cur1;
      END Block2;
    END Block1;
  END Block0$$

CREATE FUNCTION `func_annualExamsViews`(`StudentID` INT, `AcademicYearID` INT) RETURNS int(11)
DETERMINISTIC
  BEGIN
    SET @Output = 0;
-- Create a Temporary Table to Hold The Values
    DROP TEMPORARY TABLE IF EXISTS AnnualSubjectViewsResultTable;
    CREATE TEMPORARY TABLE IF NOT EXISTS AnnualSubjectViewsResultTable
    (
-- Add the column definitions for the TABLE variable here
      subject_id INT,
      subject_name VARCHAR(60),
      first_term Decimal(6, 2),
      second_term Decimal(6, 2),
      third_term Decimal(6, 2),
      annual_average Decimal(6, 2),
      annual_grade VARCHAR(50)
    );

    CALL proc_examsDetailsReportViews(AcademicYearID, 2);

      Block0: BEGIN
-- Set three of those variable to get the 1st, 2nd and 3rd terms in that year passed as parameter of the student
      SET @FirstTerm = (SELECT academic_term_id FROM academic_terms WHERE academic_year_id = AcademicYearID AND term_type_id = 1);
      SET @SecondTerm = (SELECT academic_term_id FROM academic_terms WHERE academic_year_id = AcademicYearID AND term_type_id = 2);
      SET @ThirdTerm = (SELECT academic_term_id FROM academic_terms WHERE academic_year_id = AcademicYearID AND term_type_id = 3);
      SET @ClassGroupID = (SELECT classgroup_id FROM ExamsDetailsResultTable WHERE academic_year_id=AcademicYearID AND student_id=StudentID LIMIT 1);

        Block1: BEGIN
-- Declare Variable to be used in looping through the recordset or cursor
        DECLARE done1 BOOLEAN DEFAULT FALSE;
        DECLARE SubjectID int;
        DECLARE SubjectName, TermName varchar(60);
        DECLARE cur1 CURSOR FOR
-- Populate the cursor with the values in a record i want to iterate through
          SELECT subject_id, subject_name
          FROM ExamsDetailsResultTable WHERE student_id=StudentID AND academic_year_id=AcademicYearID
          GROUP BY subject_id, subject_name;

        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;
-- Open The Cursor For Iterating Through The Recordset cur1
        OPEN cur1;
        REPEAT
          FETCH cur1 INTO SubjectID, SubjectName;
-- Test to check if the cursor still have a next record
          IF NOT done1 THEN
            BEGIN
-- Sets the students scores in a particular subject that he or she offered in that year(i.e 1st, 2nd and 3rd terms)
              SET @FirstTermSubjectScore = (SELECT studentPercentTotal FROM ExamsDetailsResultTable WHERE academic_term_id=@FirstTerm AND student_id=StudentID AND subject_id=SubjectID);
              SET @SecondTermSubjectScore = (SELECT studentPercentTotal FROM ExamsDetailsResultTable WHERE academic_term_id=@SecondTerm AND student_id=StudentID AND subject_id=SubjectID);
              SET @ThirdTermSubjectScore = (SELECT studentPercentTotal FROM ExamsDetailsResultTable WHERE academic_term_id=@ThirdTerm AND student_id=StudentID AND subject_id=SubjectID);

              BEGIN
-- Get the average of a particular subject that he or she offered in that year and also check if any term was missed
                IF @FirstTermSubjectScore IS NOT NULL AND @SecondTermSubjectScore IS NOT NULL AND @ThirdTermSubjectScore IS NOT NULL THEN
                  SET @AnnualSubjectAverage = (@FirstTermSubjectScore + @SecondTermSubjectScore + @ThirdTermSubjectScore) / 3;
                ElSEIF	@FirstTermSubjectScore IS NOT NULL AND @SecondTermSubjectScore IS NOT NULL AND @ThirdTermSubjectScore IS NULL THEN
                  SET @AnnualSubjectAverage = (@FirstTermSubjectScore + @SecondTermSubjectScore ) / 2;
                ElSEIF	@FirstTermSubjectScore IS NOT NULL AND @SecondTermSubjectScore IS NULL AND @ThirdTermSubjectScore IS NOT NULL THEN
                  SET @AnnualSubjectAverage = (@FirstTermSubjectScore + @ThirdTermSubjectScore ) / 2;
                ElSEIF	@FirstTermSubjectScore IS NULL AND @SecondTermSubjectScore IS NOT NULL AND @ThirdTermSubjectScore IS NOT NULL THEN
                  SET @AnnualSubjectAverage = (@SecondTermSubjectScore + @ThirdTermSubjectScore) / 2;
                ElSEIF	@FirstTermSubjectScore IS NOT NULL AND @SecondTermSubjectScore IS NULL AND @ThirdTermSubjectScore IS NULL THEN
                  SET @AnnualSubjectAverage = @FirstTermSubjectScore;
                ElSEIF	@FirstTermSubjectScore IS NULL AND @SecondTermSubjectScore IS NOT NULL AND @ThirdTermSubjectScore IS NULL THEN
                  SET @AnnualSubjectAverage = @SecondTermSubjectScore;
                ElSEIF	@FirstTermSubjectScore IS NULL AND @SecondTermSubjectScore IS NULL AND @ThirdTermSubjectScore IS NOT NULL THEN
                  SET @AnnualSubjectAverage = @ThirdTermSubjectScore;
                ELSE
                  SET @AnnualSubjectAverage = 0;
                END IF;
              END;
-- Set the annal grade for each subject
              BEGIN
                SET @AnnualGrade = (SELECT grade FROM grades WHERE @AnnualSubjectAverage BETWEEN lower_bound AND upper_bound AND classgroup_id=@ClassGroupID LIMIT 1);
              END;
              BEGIN
-- Insert into the resultant table that will display the computed results
                INSERT INTO AnnualSubjectViewsResultTable
                VALUES(SubjectID, SubjectName, @FirstTermSubjectScore, @SecondTermSubjectScore, @ThirdTermSubjectScore,	@AnnualSubjectAverage, @AnnualGrade);
              END;
            END;
          END IF;
        UNTIL done1 END REPEAT;
        CLOSE cur1;
      END Block1;
    END Block0;
    SET @Output = (SELECT COUNT(*) FROM AnnualSubjectViewsResultTable);
    RETURN @Output;
  END$$

CREATE FUNCTION `fun_getAttendSummary`(TermID INT, ClassID INT) RETURNS int(11)
DETERMINISTIC
    Block0: BEGIN
    SET @Output = 0;
-- Create a Temporary Table to Hold The Values
    DROP TEMPORARY TABLE IF EXISTS AttendSummaryResultTable;
    CREATE TEMPORARY TABLE IF NOT EXISTS AttendSummaryResultTable
    (
-- Add the column definitions for the TABLE variable here
      student_id INT,
      student_no VARCHAR(20),
      student_name VARCHAR(70),
      total_attendance INT,
      days_present INT,
      days_absent INT,
      class_name VARCHAR(50),
      head_tutor VARCHAR(50),
      academic_term VARCHAR(50)
    );
      Block2: BEGIN
      SET @TotalAttend = (SELECT COUNT(attend_id) FROM attends WHERE class_id=ClassID AND academic_term_id=TermID LIMIT 1);

      INSERT INTO AttendSummaryResultTable
        SELECT a.student_id, c.student_no, c.student_name, @TotalAttend, COUNT(a.student_id),
          (@TotalAttend - COUNT(a.student_id)), b.class_name, b.head_tutor, b.academic_term
        FROM students_classlevelviews c
          INNER JOIN attend_details a ON c.student_id=a.student_id
          INNER JOIN attend_headerviews b ON a.attend_id=b.attend_id
        WHERE b.class_id=ClassID AND b.academic_term_id=TermID GROUP BY student_id;

    END Block2;

    SET @Output = (SELECT COUNT(*) FROM AttendSummaryResultTable);
    RETURN @Output;
  END Block0$$

CREATE FUNCTION `fun_getClassHeadTutor`(ClassLevelID INT, YearID INT) RETURNS int(3)
DETERMINISTIC
    Block0: BEGIN
    SET @Output = 0;
-- Create a Temporary Table to Hold The Values
    DROP TEMPORARY TABLE IF EXISTS ClassHeadTutorResultTable;
    CREATE TEMPORARY TABLE IF NOT EXISTS ClassHeadTutorResultTable
    (
-- Add the column definitions for the TABLE variable here
      class_id INT,
      class_name VARCHAR(50),
      classlevel_id INT,
      student_count INT,
      teacher_class_id INT NULL,
      employee_id INT NULL,
      employee_name VARCHAR(80),
      academic_year_id INT
    );
      Block2: BEGIN
      DECLARE done1 BOOLEAN DEFAULT FALSE;
      DECLARE ClassID, Classlevel_ID INT;
      DECLARE ClassName VARCHAR(50);
      DECLARE cur1 CURSOR FOR
        SELECT a.class_id, a.class_name, a.classlevel_id
        FROM classrooms a WHERE a.classlevel_id=ClassLevelID;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;

-- Open The Cursor For Iterating Through The Recordset cur1
      OPEN cur1;
      REPEAT
        FETCH cur1 INTO ClassID, ClassName, Classlevel_ID;
        IF NOT done1 THEN
          BEGIN
            SET @StudentCount = (SELECT COUNT(*) FROM students_classes WHERE class_id=ClassID AND academic_year_id=YearID);
            SET @TeachClassID = (SELECT teacher_class_id FROM teachers_classes WHERE class_id=ClassID AND academic_year_id=YearID LIMIT 1);
            SET @EmployeeID = (SELECT employee_id FROM teachers_classes WHERE teacher_class_id=@TeachClassID);
            SET @EmployeeName = (SELECT CONCAT(first_name, ' ', other_name) FROM employees WHERE employee_id=@EmployeeID);

            INSERT INTO ClassHeadTutorResultTable(class_id, class_name, classlevel_id, student_count, teacher_class_id, employee_id, employee_name, academic_year_id)
              SELECT ClassID, ClassName, Classlevel_ID, @StudentCount, @TeachClassID, @EmployeeID, @EmployeeName, YearID;
          END;
        END IF;
      UNTIL done1 END REPEAT;
      CLOSE cur1;
    END Block2;

    SET @Output = (SELECT COUNT(*) FROM ClassHeadTutorResultTable);
    RETURN @Output;
  END Block0$$

CREATE FUNCTION `fun_getSubjectClasslevel`(term_id INT) RETURNS int(11)
DETERMINISTIC
    Block0: BEGIN
    SET @Output = 0;
-- Create a Temporary Table to Hold The Values
    DROP TEMPORARY TABLE IF EXISTS SubjectClasslevelResultTable;
    CREATE TEMPORARY TABLE IF NOT EXISTS SubjectClasslevelResultTable
    (
-- Add the column definitions for the TABLE variable here
      class_name VARCHAR(50),
      subject_name VARCHAR(50),
      subject_id INT,
      class_id INT,
      classlevel_id INT,
      subject_classlevel_id INT,
      classlevel VARCHAR(50),
      examstatus_id INT,
      exam_status VARCHAR(50),
      academic_term_id INT,
      academic_term VARCHAR(50),
      academic_year_id INT,
      academic_year VARCHAR(50)
    );
      Block2: BEGIN
      DECLARE done1 BOOLEAN DEFAULT FALSE;
      DECLARE si, ci, cli, scli, esi, ati, ayi  INT;
      DECLARE cn, sn, cl, es, atn, ayn VARCHAR(30);
      DECLARE cur1 CURSOR FOR SELECT * FROM subject_classlevelviews WHERE academic_term_id=term_id;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;

-- Open The Cursor For Iterating Through The Recordset cur1
      OPEN cur1;
      REPEAT
        FETCH cur1 INTO cn, sn, si, ci, cli, scli, cl, esi, es, ati, atn, ayi, ayn;
        IF NOT done1 THEN
          BEGIN
            IF ci IS NOT NULL THEN
-- Insert into the resultant table that will display the results
              BEGIN
                INSERT INTO SubjectClasslevelResultTable VALUES(cn, sn, si, ci, cli, scli, cl, esi, es, ati, atn, ayi, ayn);
              END;
            ELSE
              BEGIN
                INSERT INTO SubjectClasslevelResultTable(class_name, subject_name,subject_id, class_id, classlevel_id, subject_classlevel_id,
                                                         classlevel, examstatus_id, exam_status, academic_term_id, academic_term, academic_year_id, academic_year)
                  SELECT classrooms.class_name, sn, si, classrooms.class_id, cli, scli, cl, esi, es, ati, atn, ayi, ayn
                  FROM   classrooms INNER JOIN classlevels ON classrooms.classlevel_id = classlevels.classlevel_id
                  WHERE classrooms.classlevel_id = cli;
              END;
            END IF;
          END;
        END IF;
      UNTIL done1 END REPEAT;
      CLOSE cur1;
    END Block2;

    SET @Output = (SELECT COUNT(*) FROM SubjectClasslevelResultTable);
    RETURN @Output;
  END Block0$$

CREATE FUNCTION `getCurrentTermID`() RETURNS int(11)
DETERMINISTIC
  BEGIN
    RETURN (SELECT academic_term_id FROM academic_terms WHERE term_status_id=1 LIMIT 1);
  END$$

CREATE FUNCTION `getCurrentYearID`() RETURNS int(11)
DETERMINISTIC
  BEGIN
    RETURN (SELECT academic_year_id FROM academic_years WHERE year_status_id=1 LIMIT 1);
  END$$

CREATE FUNCTION `SPLIT_STR`(
  x VARCHAR(255),
  delim VARCHAR(12),
  pos INT
) RETURNS varchar(255) CHARSET latin1
DETERMINISTIC
  RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(x, delim, pos),
                           LENGTH(SUBSTRING_INDEX(x, delim, pos -1)) + 1),
                 delim, '')$$

DELIMITER ;

CREATE TABLE IF NOT EXISTS `academic_terms` (
  `academic_term_id` int(11) NOT NULL,
  `academic_term` varchar(50) DEFAULT NULL,
  `academic_year_id` int(11) unsigned DEFAULT NULL,
  `term_status_id` int(11) unsigned DEFAULT NULL,
  `term_type_id` int(11) unsigned DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `academic_years` (
  `academic_year_id` int(11) unsigned NOT NULL,
  `academic_year` varchar(50) DEFAULT NULL,
  `year_status_id` int(11) unsigned DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `acos` (
  `id` int(10) NOT NULL,
  `parent_id` int(10) DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `foreign_key` int(10) DEFAULT NULL,
  `alias` varchar(255) DEFAULT NULL,
  `lft` int(10) DEFAULT NULL,
  `rght` int(10) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=130 ;

INSERT INTO `acos` (`id`, `parent_id`, `model`, `foreign_key`, `alias`, `lft`, `rght`) VALUES
  (1, NULL, NULL, NULL, 'controllers', 1, 258),
  (2, 1, NULL, NULL, 'AcademicTermsController', 2, 5),
  (3, 2, NULL, NULL, 'ajax_get_terms', 3, 4),
  (4, 1, NULL, NULL, 'AcademicYearsController', 6, 7),
  (5, 1, NULL, NULL, 'AppController', 8, 9),
  (6, 1, NULL, NULL, 'AttendsController', 10, 31),
  (7, 6, NULL, NULL, 'index', 11, 12),
  (8, 6, NULL, NULL, 'search_students', 13, 14),
  (9, 6, NULL, NULL, 'take_attend', 15, 16),
  (10, 6, NULL, NULL, 'validateIfExist', 17, 18),
  (11, 6, NULL, NULL, 'search_attend', 19, 20),
  (12, 6, NULL, NULL, 'view', 21, 22),
  (13, 6, NULL, NULL, 'edit', 23, 24),
  (14, 6, NULL, NULL, 'search_summary', 25, 26),
  (15, 6, NULL, NULL, 'summary', 27, 28),
  (16, 6, NULL, NULL, 'details', 29, 30),
  (17, 1, NULL, NULL, 'ClassroomsController', 32, 45),
  (18, 17, NULL, NULL, 'ajax_get_classes', 33, 34),
  (19, 17, NULL, NULL, 'index', 35, 36),
  (20, 17, NULL, NULL, 'myclass', 37, 38),
  (21, 17, NULL, NULL, 'search_classes', 39, 40),
  (22, 17, NULL, NULL, 'assign_head_tutor', 41, 42),
  (23, 17, NULL, NULL, 'view', 43, 44),
  (24, 1, NULL, NULL, 'DashboardController', 46, 61),
  (25, 24, NULL, NULL, 'index', 47, 48),
  (26, 24, NULL, NULL, 'tutor', 49, 50),
  (27, 24, NULL, NULL, 'studentGender', 51, 52),
  (28, 24, NULL, NULL, 'studentStauts', 53, 54),
  (29, 24, NULL, NULL, 'studentClasslevel', 55, 56),
  (30, 24, NULL, NULL, 'classHeadTutor', 57, 58),
  (31, 24, NULL, NULL, 'subjectHeadTutor', 59, 60),
  (32, 1, NULL, NULL, 'EmployeesController', 62, 79),
  (33, 32, NULL, NULL, 'autoComplete', 63, 64),
  (34, 32, NULL, NULL, 'validate_form', 65, 66),
  (35, 32, NULL, NULL, 'index', 67, 68),
  (36, 32, NULL, NULL, 'register', 69, 70),
  (37, 32, NULL, NULL, 'view', 71, 72),
  (38, 32, NULL, NULL, 'adjust', 73, 74),
  (39, 32, NULL, NULL, 'delete', 75, 76),
  (40, 32, NULL, NULL, 'statusUpdate', 77, 78),
  (41, 1, NULL, NULL, 'ExamsController', 80, 105),
  (42, 41, NULL, NULL, 'index', 81, 82),
  (43, 41, NULL, NULL, 'setup_exam', 83, 84),
  (44, 41, NULL, NULL, 'get_exam_setup', 85, 86),
  (45, 41, NULL, NULL, 'search_subjects_assigned', 87, 88),
  (46, 41, NULL, NULL, 'search_subjects_examSetup', 89, 90),
  (47, 41, NULL, NULL, 'enter_scores', 91, 92),
  (48, 41, NULL, NULL, 'view_scores', 93, 94),
  (49, 41, NULL, NULL, 'search_student_classlevel', 95, 96),
  (50, 41, NULL, NULL, 'term_scorestd', 97, 98),
  (51, 41, NULL, NULL, 'term_scorecls', 99, 100),
  (52, 41, NULL, NULL, 'annual_scorestd', 101, 102),
  (53, 41, NULL, NULL, 'annual_scorecls', 103, 104),
  (54, 1, NULL, NULL, 'HomeController', 106, 125),
  (55, 54, NULL, NULL, 'index', 107, 108),
  (56, 54, NULL, NULL, 'students', 109, 110),
  (57, 54, NULL, NULL, 'record', 111, 112),
  (58, 54, NULL, NULL, 'exam', 113, 114),
  (59, 54, NULL, NULL, 'search_student', 115, 116),
  (60, 54, NULL, NULL, 'term_scorestd', 117, 118),
  (61, 54, NULL, NULL, 'annual_scorestd', 119, 120),
  (62, 54, NULL, NULL, 'view_stdfees', 121, 122),
  (63, 54, NULL, NULL, 'change', 123, 124),
  (64, 1, NULL, NULL, 'ItemsController', 126, 139),
  (65, 64, NULL, NULL, 'index', 127, 128),
  (66, 64, NULL, NULL, 'validateIfExist', 129, 130),
  (67, 64, NULL, NULL, 'process_fees', 131, 132),
  (68, 64, NULL, NULL, 'bill_students', 133, 134),
  (69, 64, NULL, NULL, 'view_stdfees', 135, 136),
  (70, 64, NULL, NULL, 'view_clsfees', 137, 138),
  (71, 1, NULL, NULL, 'LocalGovtsController', 140, 143),
  (72, 71, NULL, NULL, 'ajax_get_local_govt', 141, 142),
  (73, 1, NULL, NULL, 'MessagesController', 144, 153),
  (74, 73, NULL, NULL, 'index', 145, 146),
  (75, 73, NULL, NULL, 'send', 147, 148),
  (76, 73, NULL, NULL, 'search_student_classlevel', 149, 150),
  (77, 73, NULL, NULL, 'encrypt', 151, 152),
  (78, 1, NULL, NULL, 'RecordsController', 154, 177),
  (79, 78, NULL, NULL, 'deleteIDs', 155, 156),
  (80, 78, NULL, NULL, 'index', 157, 158),
  (81, 78, NULL, NULL, 'academic_year', 159, 160),
  (82, 78, NULL, NULL, 'class_group', 161, 162),
  (83, 78, NULL, NULL, 'class_level', 163, 164),
  (84, 78, NULL, NULL, 'class_room', 165, 166),
  (85, 78, NULL, NULL, 'grade', 167, 168),
  (86, 78, NULL, NULL, 'subject_group', 169, 170),
  (87, 78, NULL, NULL, 'subject', 171, 172),
  (88, 78, NULL, NULL, 'item', 173, 174),
  (89, 78, NULL, NULL, 'item_bill', 175, 176),
  (90, 1, NULL, NULL, 'SponsorsController', 178, 193),
  (91, 90, NULL, NULL, 'autoComplete', 179, 180),
  (92, 90, NULL, NULL, 'validate_form', 181, 182),
  (93, 90, NULL, NULL, 'index', 183, 184),
  (94, 90, NULL, NULL, 'register', 185, 186),
  (95, 90, NULL, NULL, 'view', 187, 188),
  (96, 90, NULL, NULL, 'adjust', 189, 190),
  (97, 90, NULL, NULL, 'delete', 191, 192),
  (98, 1, NULL, NULL, 'StudentsClassesController', 194, 201),
  (99, 98, NULL, NULL, 'assign', 195, 196),
  (100, 98, NULL, NULL, 'search', 197, 198),
  (101, 98, NULL, NULL, 'search_all', 199, 200),
  (102, 1, NULL, NULL, 'StudentsController', 202, 217),
  (103, 102, NULL, NULL, 'validate_form', 203, 204),
  (104, 102, NULL, NULL, 'index', 205, 206),
  (105, 102, NULL, NULL, 'view', 207, 208),
  (106, 102, NULL, NULL, 'register', 209, 210),
  (107, 102, NULL, NULL, 'adjust', 211, 212),
  (108, 102, NULL, NULL, 'delete', 213, 214),
  (109, 102, NULL, NULL, 'statusUpdate', 215, 216),
  (110, 1, NULL, NULL, 'SubjectsController', 218, 239),
  (111, 110, NULL, NULL, 'ajax_get_subjects', 219, 220),
  (112, 110, NULL, NULL, 'add2class', 221, 222),
  (113, 110, NULL, NULL, 'assign', 223, 224),
  (114, 110, NULL, NULL, 'validateIfExist', 225, 226),
  (115, 110, NULL, NULL, 'search_all', 227, 228),
  (116, 110, NULL, NULL, 'assign_tutor', 229, 230),
  (117, 110, NULL, NULL, 'search_assigned', 231, 232),
  (118, 110, NULL, NULL, 'modify_assign', 233, 234),
  (119, 110, NULL, NULL, 'search_students', 235, 236),
  (120, 110, NULL, NULL, 'updateStudentsSubjects', 237, 238),
  (121, 1, NULL, NULL, 'UsersController', 240, 257),
  (122, 121, NULL, NULL, 'login', 241, 242),
  (123, 121, NULL, NULL, 'logout', 243, 244),
  (124, 121, NULL, NULL, 'index', 245, 246),
  (125, 121, NULL, NULL, 'register', 247, 248),
  (126, 121, NULL, NULL, 'forget_password', 249, 250),
  (127, 121, NULL, NULL, 'adjust', 251, 252),
  (128, 121, NULL, NULL, 'change', 253, 254),
  (129, 121, NULL, NULL, 'statusUpdate', 255, 256);

CREATE TABLE IF NOT EXISTS `aros` (
  `id` int(10) NOT NULL,
  `parent_id` int(10) DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `foreign_key` int(10) DEFAULT NULL,
  `alias` varchar(255) DEFAULT NULL,
  `lft` int(10) DEFAULT NULL,
  `rght` int(10) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

INSERT INTO `aros` (`id`, `parent_id`, `model`, `foreign_key`, `alias`, `lft`, `rght`) VALUES
  (1, NULL, NULL, NULL, 'expired_users', 1, 2),
  (2, NULL, NULL, NULL, 'web_users', 3, 4),
  (3, NULL, NULL, NULL, 'emp_users', 5, 6),
  (4, NULL, NULL, NULL, 'ict_users', 7, 8),
  (5, NULL, NULL, NULL, 'app_users', 9, 10),
  (6, NULL, NULL, NULL, 'adm_users', 11, 12);

CREATE TABLE IF NOT EXISTS `aros_acos` (
  `id` int(10) NOT NULL,
  `aro_id` int(10) NOT NULL,
  `aco_id` int(10) NOT NULL,
  `_create` varchar(2) NOT NULL DEFAULT '0',
  `_read` varchar(2) NOT NULL DEFAULT '0',
  `_update` varchar(2) NOT NULL DEFAULT '0',
  `_delete` varchar(2) NOT NULL DEFAULT '0'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=40 ;

INSERT INTO `aros_acos` (`id`, `aro_id`, `aco_id`, `_create`, `_read`, `_update`, `_delete`) VALUES
  (1, 1, 1, '-1', '-1', '-1', '-1'),
  (2, 2, 1, '-1', '-1', '-1', '-1'),
  (3, 2, 54, '1', '1', '1', '1'),
  (4, 3, 1, '-1', '-1', '-1', '-1'),
  (5, 3, 24, '1', '1', '1', '1'),
  (6, 3, 41, '1', '1', '1', '1'),
  (7, 3, 6, '1', '1', '1', '1'),
  (8, 3, 105, '1', '1', '1', '1'),
  (9, 3, 20, '1', '1', '1', '1'),
  (10, 3, 23, '1', '1', '1', '1'),
  (11, 3, 38, '0', '0', '1', '0'),
  (12, 4, 1, '-1', '-1', '-1', '-1'),
  (13, 4, 24, '1', '1', '1', '1'),
  (14, 4, 41, '1', '1', '1', '1'),
  (15, 4, 78, '1', '1', '1', '1'),
  (16, 4, 6, '1', '1', '1', '1'),
  (17, 4, 17, '1', '1', '1', '1'),
  (18, 4, 102, '1', '1', '1', '1'),
  (19, 4, 104, '1', '1', '1', '1'),
  (20, 4, 105, '1', '1', '1', '1'),
  (21, 4, 106, '1', '0', '0', '0'),
  (22, 4, 107, '0', '0', '1', '0'),
  (23, 4, 108, '0', '0', '0', '-1'),
  (24, 4, 90, '1', '1', '1', '1'),
  (25, 4, 93, '1', '1', '1', '1'),
  (26, 4, 94, '1', '0', '0', '0'),
  (27, 4, 96, '0', '0', '1', '0'),
  (28, 4, 97, '0', '0', '0', '-1'),
  (29, 4, 32, '1', '1', '1', '1'),
  (30, 4, 35, '1', '1', '1', '1'),
  (31, 4, 36, '1', '0', '0', '0'),
  (32, 4, 38, '0', '0', '1', '0'),
  (33, 4, 39, '0', '0', '0', '-1'),
  (34, 4, 110, '1', '1', '1', '1'),
  (35, 4, 112, '1', '1', '1', '1'),
  (36, 4, 64, '1', '1', '1', '1'),
  (37, 4, 67, '-1', '-1', '-1', '-1'),
  (38, 6, 1, '1', '1', '1', '1'),
  (39, 6, 54, '-1', '-1', '-1', '-1');

CREATE TABLE IF NOT EXISTS `attend_details` (
  `student_id` int(11) DEFAULT NULL,
  `attend_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
CREATE TABLE IF NOT EXISTS `attend_headerviews` (
   `attend_id` int(11)
  ,`class_id` int(11)
  ,`employee_id` int(11)
  ,`academic_term_id` int(11)
  ,`attend_date` date
  ,`class_name` varchar(50)
  ,`classlevel_id` int(11)
  ,`academic_term` varchar(50)
  ,`academic_year_id` int(11) unsigned
  ,`head_tutor` varchar(151)
);
CREATE TABLE IF NOT EXISTS `attends` (
  `attend_id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `academic_term_id` int(11) NOT NULL,
  `attend_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `classgroups` (
  `classgroup_id` int(11) unsigned NOT NULL,
  `classgroup` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `classlevels` (
  `classlevel_id` int(11) NOT NULL,
  `classlevel` varchar(50) DEFAULT NULL,
  `classgroup_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `classrooms` (
  `class_id` int(11) NOT NULL,
  `class_name` varchar(50) DEFAULT NULL,
  `classlevel_id` int(11) DEFAULT NULL,
  `class_size` int(11) DEFAULT NULL,
  `class_status_id` int(3) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `countries` (
  `country_id` int(3) unsigned NOT NULL,
  `country_name` varchar(50) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=234 ;

INSERT INTO `countries` (`country_id`, `country_name`) VALUES
  (1, 'Albania'),
  (2, 'Algeria'),
  (3, 'American Samoa'),
  (4, 'Anguilla'),
  (5, 'Antigua Barbuda'),
  (6, 'Argentina'),
  (7, 'Aruba'),
  (8, 'Australia'),
  (9, 'Austria'),
  (10, 'Azores'),
  (11, 'Bahamas'),
  (12, 'Bahrain'),
  (13, 'Bangladesh'),
  (14, 'Barbados'),
  (15, 'Belarus'),
  (16, 'Belgium'),
  (17, 'Belize'),
  (18, 'Benin'),
  (19, 'Bermuda'),
  (20, 'Bolivia'),
  (21, 'Bonaire'),
  (22, 'Bosnia'),
  (23, 'Botswana'),
  (24, 'Brazil'),
  (25, 'British Virgin Islands'),
  (26, 'Brunei'),
  (27, 'Bulgaria'),
  (28, 'Burkina Faso'),
  (29, 'Burundi'),
  (30, 'Cambodia'),
  (31, 'Cameroon'),
  (32, 'Canada'),
  (33, 'Canary Islands'),
  (34, 'Cape Verde Islands'),
  (35, 'Cayman Islands'),
  (36, 'Central African Republic'),
  (37, 'Chad'),
  (38, 'Channel Islands'),
  (39, 'Chile'),
  (40, 'China'),
  (41, 'Colombia'),
  (42, 'Con '),
  (43, 'Cook Islands'),
  (44, 'Costa Rica'),
  (45, 'Croatia'),
  (46, 'Curacao'),
  (47, 'Cyprus'),
  (48, 'Czech Republic'),
  (49, 'Denmark'),
  (50, 'Djibouti'),
  (51, 'Dominica'),
  (52, 'Dominican Republic'),
  (53, 'Ecuador'),
  (54, 'Egypt'),
  (55, 'El Salvador'),
  (56, 'England'),
  (57, 'Equitorial Guinea'),
  (58, 'Eritrea'),
  (59, 'Estonia'),
  (60, 'Ethiopia'),
  (61, 'Faeroe Islands'),
  (62, 'Federated States of Micronesia'),
  (63, 'Fiji'),
  (64, 'Finland'),
  (65, 'France'),
  (66, 'French Guiana'),
  (67, 'French Polynesia'),
  (68, 'Gabon'),
  (69, 'Gambia'),
  (70, 'Georgia'),
  (71, 'Germany'),
  (72, 'Ghana'),
  (73, 'Gibraltar'),
  (74, 'Greece'),
  (75, 'Greenland'),
  (76, 'Grenada'),
  (77, 'Guadeloupe'),
  (78, 'Guam'),
  (79, 'Guatemala'),
  (80, 'Guinea'),
  (81, 'Guinea-Bissau'),
  (82, 'Guyana'),
  (83, 'Haiti'),
  (84, 'Holland'),
  (85, 'Honduras'),
  (86, 'Hong Kong'),
  (87, 'Hungary'),
  (88, 'Iceland'),
  (89, 'India'),
  (90, 'Indonesia'),
  (91, 'Ireland'),
  (92, 'Israel'),
  (93, 'Italy'),
  (94, 'Ivory Coast'),
  (95, 'Jamaica'),
  (96, 'Japan'),
  (97, 'Jordan'),
  (98, 'Kazakhstan'),
  (99, 'Kenya'),
  (100, 'Kiribati'),
  (101, 'Kosrae'),
  (102, 'Kuwait'),
  (103, 'Kyrgyzstan'),
  (104, 'Laos'),
  (105, 'Latvia'),
  (106, 'Lebanon'),
  (107, 'Lesotho'),
  (108, 'Liberia'),
  (109, 'Liechtenstein'),
  (110, 'Lithuania'),
  (111, 'Luxembourg'),
  (112, 'Macau'),
  (113, 'Macedonia'),
  (114, 'Madagascar'),
  (115, 'Madeira'),
  (116, 'Malawi'),
  (117, 'Malaysia'),
  (118, 'Maldives'),
  (119, 'Mali'),
  (120, 'Malta'),
  (121, 'Marshall Islands'),
  (122, 'Martinique'),
  (123, 'Mauritania'),
  (124, 'Mauritius'),
  (125, 'Mexico'),
  (126, 'Moldova'),
  (127, 'Monaco'),
  (128, 'Montserrat'),
  (129, 'Morocco'),
  (130, 'Mozambique'),
  (131, 'Myanmar'),
  (132, 'Namibia'),
  (133, 'Nepal'),
  (134, 'Netherlands'),
  (135, 'Netherlands Antilles'),
  (136, 'New Caledonia'),
  (137, 'New Zealand'),
  (138, 'Nicaragua'),
  (139, 'Niger'),
  (140, 'Nigeria'),
  (141, 'Norfolk Island'),
  (142, 'Northern Ireland'),
  (143, 'Northern Mariana Islands'),
  (144, 'Norway'),
  (145, 'Oman'),
  (146, 'Pakistan'),
  (147, 'Palau'),
  (148, 'Panama'),
  (149, 'Papua New Guinea'),
  (150, 'Paraguay'),
  (151, 'Peru'),
  (152, 'Philippines'),
  (153, 'Poland'),
  (154, 'Ponape'),
  (155, 'Portugal'),
  (156, 'Puerto Rico'),
  (157, 'Qatar'),
  (158, 'Republic of Ireland'),
  (159, 'Republic of Yemen'),
  (160, 'Reunion'),
  (161, 'Romania'),
  (162, 'Rota'),
  (163, 'Russia'),
  (164, 'Rwanda'),
  (165, 'Saba'),
  (166, 'Saipan'),
  (167, 'Saudi Arabia'),
  (168, 'Scotland'),
  (169, 'Senegal'),
  (170, 'Seychelles'),
  (171, 'Sierra Leone'),
  (172, 'Singapore'),
  (173, 'Slovakia'),
  (174, 'Slovenia'),
  (175, 'Solomon Islands'),
  (176, 'South Africa'),
  (177, 'South Korea'),
  (178, 'Spain'),
  (179, 'Sri Lanka'),
  (180, 'St. Barthelemy'),
  (181, 'St. Christopher'),
  (182, 'St. Croix'),
  (183, 'St. Eustatius'),
  (184, 'St. John'),
  (185, 'St. Kitts Nevis'),
  (186, 'St. Lucia'),
  (187, 'St. Maarten'),
  (188, 'St. Martin'),
  (189, 'St. Thomas'),
  (190, 'St. Vincent the Grenadines'),
  (191, 'Sudan'),
  (192, 'Suriname'),
  (193, 'Swaziland'),
  (194, 'Sweden'),
  (195, 'Switzerland'),
  (196, 'Syria'),
  (197, 'Tahiti'),
  (198, 'Taiwan'),
  (199, 'Tajikistan'),
  (200, 'Tanzania'),
  (201, 'Thailand'),
  (202, 'Tinian'),
  (203, 'To '),
  (204, 'Tonga'),
  (205, 'Tortola'),
  (206, 'Trinidad Toba '),
  (207, 'Truk'),
  (208, 'Tunisia'),
  (209, 'Turkey'),
  (210, 'Turks Caicos Islands'),
  (211, 'Tuvalu'),
  (212, 'Uganda'),
  (213, 'Ukraine'),
  (214, 'Union Island'),
  (215, 'United Arab Emirates'),
  (216, 'United Kingdom'),
  (217, 'United States'),
  (218, 'Uruguay'),
  (219, 'US Virgin Islands'),
  (220, 'Uzbekistan'),
  (221, 'Vanuatu'),
  (222, 'Venezuela'),
  (223, 'Vietnam'),
  (224, 'Virgin  rda'),
  (225, 'Wake Island'),
  (226, 'Wales'),
  (227, 'Wallis Futuna Islands'),
  (228, 'Western Samoa'),
  (229, 'Yap'),
  (230, 'Yu slavia'),
  (231, 'Zaire'),
  (232, 'Zambia'),
  (233, 'Zimbabwe');

CREATE TABLE IF NOT EXISTS `employee_qualifications` (
  `employee_qualification_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `institution` text NOT NULL,
  `qualification` varchar(150) DEFAULT NULL,
  `date_from` date DEFAULT NULL,
  `date_to` date DEFAULT NULL,
  `qualification_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `employee_types` (
  `employee_type_id` int(11) unsigned NOT NULL,
  `employee_type` varchar(100) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=8 ;

INSERT INTO `employee_types` (`employee_type_id`, `employee_type`) VALUES
  (1, 'Applicants'),
  (2, 'Auxiliary'),
  (3, 'Contract'),
  (4, 'Corper/IT'),
  (5, 'OutSourced Staffs'),
  (6, 'Permanent'),
  (7, 'Retired/Pension');

CREATE TABLE IF NOT EXISTS `employees` (
  `employee_id` int(11) NOT NULL,
  `employee_no` varchar(10) NOT NULL,
  `salutation_id` int(10) unsigned DEFAULT NULL,
  `first_name` varchar(50) DEFAULT NULL,
  `other_name` varchar(100) DEFAULT NULL,
  `gender` varchar(10) DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `image_url` varchar(50) DEFAULT NULL,
  `contact_address` text,
  `employee_type_id` int(11) DEFAULT NULL,
  `mobile_number1` varchar(20) DEFAULT NULL,
  `mobile_number2` varchar(20) DEFAULT NULL,
  `marital_status` varchar(20) DEFAULT NULL,
  `country_id` int(11) DEFAULT NULL,
  `state_id` int(11) DEFAULT NULL,
  `local_govt_id` int(11) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `next_ofkin_name` varchar(70) DEFAULT NULL,
  `next_ofkin_number` varchar(15) DEFAULT NULL,
  `next_ofkin_relate` varchar(30) DEFAULT NULL,
  `form_of_identity` varchar(100) DEFAULT NULL,
  `identity_no` varchar(30) DEFAULT NULL,
  `identity_expiry_date` date DEFAULT NULL,
  `status_id` int(2) NOT NULL DEFAULT '2',
  `created_by` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `exam_details` (
  `exam_detail_id` int(11) NOT NULL,
  `exam_id` int(11) DEFAULT NULL,
  `student_id` int(11) DEFAULT NULL,
  `ca1` decimal(4,1) DEFAULT '0.0',
  `ca2` decimal(4,1) DEFAULT '0.0',
  `exam` decimal(4,1) DEFAULT '0.0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;
CREATE TABLE IF NOT EXISTS `exam_subjectviews` (
   `exam_id` int(11) unsigned
  ,`exam_desc` text
  ,`class_id` int(11)
  ,`class_name` varchar(50)
  ,`subject_name` varchar(50)
  ,`subject_id` int(11)
  ,`subject_classlevel_id` int(11)
  ,`weightageCA1` int(11) unsigned
  ,`weightageCA2` int(11) unsigned
  ,`weightageExam` int(11) unsigned
  ,`setup_by` int(11)
  ,`exammarked_status_id` int(11)
  ,`setup_date` datetime
  ,`classlevel_id` int(11)
  ,`classlevel` varchar(50)
  ,`academic_term_id` int(11)
  ,`academic_term` varchar(50)
  ,`academic_year_id` int(11) unsigned
  ,`academic_year` varchar(50)
);
CREATE TABLE IF NOT EXISTS `exams` (
  `exam_id` int(11) unsigned NOT NULL,
  `exam_desc` text,
  `class_id` int(11) DEFAULT NULL,
  `subject_classlevel_id` int(11) DEFAULT NULL,
  `weightageCA1` int(11) unsigned DEFAULT NULL,
  `weightageCA2` int(11) unsigned DEFAULT NULL,
  `weightageExam` int(11) unsigned DEFAULT NULL,
  `employee_id` int(11) DEFAULT NULL,
  `exammarked_status_id` int(11) DEFAULT '2',
  `setup_date` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;
CREATE TABLE IF NOT EXISTS `examsdetails_reportviews` (
   `exam_id` int(11) unsigned
  ,`subject_id` int(11)
  ,`classlevel_id` int(11)
  ,`class_id` int(11)
  ,`student_id` int(10) unsigned
  ,`subject_name` varchar(50)
  ,`class_name` varchar(50)
  ,`student_fullname` varchar(152)
  ,`ca1` decimal(4,1)
  ,`ca2` decimal(4,1)
  ,`exam` decimal(4,1)
  ,`weightageCA1` int(11) unsigned
  ,`weightageCA2` int(11) unsigned
  ,`weightageExam` int(11) unsigned
  ,`academic_term_id` int(11)
  ,`academic_term` varchar(50)
  ,`exammarked_status_id` int(11)
  ,`academic_year_id` int(11) unsigned
  ,`academic_year` varchar(50)
  ,`classlevel` varchar(50)
  ,`classgroup_id` int(11) unsigned
);
CREATE TABLE IF NOT EXISTS `grades` (
  `grades_id` int(11) NOT NULL,
  `grade` varchar(20) DEFAULT NULL,
  `grade_abbr` varchar(3) DEFAULT NULL,
  `classgroup_id` int(11) DEFAULT NULL,
  `lower_bound` decimal(4,1) DEFAULT NULL,
  `upper_bound` decimal(4,1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `item_bills` (
  `item_bill_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `price` decimal(12,2) NOT NULL,
  `classlevel_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `item_types` (
  `item_type_id` int(11) NOT NULL,
  `item_type` varchar(50) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=4 ;

INSERT INTO `item_types` (`item_type_id`, `item_type`) VALUES
  (1, 'Universal'),
  (2, 'Variable'),
  (3, 'Electives');

CREATE TABLE IF NOT EXISTS `item_variables` (
  `item_variable_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `student_id` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `academic_term_id` int(11) NOT NULL,
  `price` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `items` (
  `item_id` int(11) NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `item_status_id` int(3) NOT NULL DEFAULT '2',
  `item_description` text NOT NULL,
  `item_type_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `local_govts` (
  `local_govt_id` int(3) unsigned NOT NULL,
  `local_govt_name` varchar(50) DEFAULT NULL,
  `state_id` int(3) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=781 ;

INSERT INTO `local_govts` (`local_govt_id`, `local_govt_name`, `state_id`) VALUES
  (1, 'Aba North', 1),
  (2, 'Aba South', 1),
  (3, 'Arochukwu', 1),
  (4, 'Bende', 1),
  (5, 'Ikwuano', 1),
  (6, 'Isiala-Ngwa North', 1),
  (7, 'Isiala-Ngwa South', 1),
  (8, 'Isuikwato', 1),
  (9, 'Ngwa', 1),
  (10, 'Obi Nwa', 1),
  (11, 'Ohafia', 1),
  (12, 'Osisioma', 1),
  (13, 'Ugwunagbo', 1),
  (14, 'Ukwa East', 1),
  (15, 'Ukwa West', 1),
  (16, 'Umuahia North', 1),
  (17, 'Umuahia South', 1),
  (18, 'Umu-Neochi', 1),
  (19, 'Demsa', 2),
  (20, 'Fufore', 2),
  (21, 'Ganaye', 2),
  (22, 'Gireri', 2),
  (23, 'Gombi', 2),
  (24, 'Guyuk', 2),
  (25, 'Hong', 2),
  (26, 'Jada', 2),
  (27, 'Lamurde', 2),
  (28, 'Madagali', 2),
  (29, 'Maiha ', 2),
  (30, 'Mayo-Belwa', 2),
  (31, 'Michika', 2),
  (32, 'Mubi North', 2),
  (33, 'Mubi South', 2),
  (34, 'Numan', 2),
  (35, 'Shelleng', 2),
  (36, 'Song', 2),
  (37, 'Toungo', 2),
  (38, 'Yola North', 2),
  (39, 'Yola South', 2),
  (40, 'Abak', 3),
  (41, 'Eastern Obolo', 3),
  (42, 'Eket', 3),
  (43, 'Esit Eket', 3),
  (44, 'Essien Udim', 3),
  (45, 'Etim Ekpo', 3),
  (46, 'Etinan', 3),
  (47, 'Ibeno', 3),
  (48, 'Ibesikpo Asutan', 3),
  (49, 'Ibiono Ibom', 3),
  (50, 'Ika', 3),
  (51, 'Ikono', 3),
  (52, 'Ikot Abasi', 3),
  (53, 'Ikot Ekpene', 3),
  (54, 'Ini', 3),
  (55, 'Itu', 3),
  (56, 'Mbo', 3),
  (57, 'Mkpat Enin', 3),
  (58, 'Nsit Atai', 3),
  (59, 'Nsit Ibom', 3),
  (60, 'Nsit Ubium', 3),
  (61, 'Obot Akara', 3),
  (62, 'Okobo', 3),
  (63, 'Onna', 3),
  (64, 'Oron ', 3),
  (65, 'Oruk Anam', 3),
  (66, 'Udung Uko', 3),
  (67, 'Ukanafun', 3),
  (68, 'Uruan', 3),
  (69, 'Urue-Offong/Oruko', 3),
  (70, 'Uyo', 3),
  (71, 'Aguata', 4),
  (72, 'Anambra East', 4),
  (73, 'Anambra West', 4),
  (74, 'Anaocha', 4),
  (75, 'Awka North', 4),
  (76, 'Awka South', 4),
  (77, 'Ayamelum', 4),
  (78, 'Dunukofia', 4),
  (79, 'Ekwusigo', 4),
  (80, 'Idemili North', 4),
  (81, 'Idemili South', 4),
  (82, 'Ihiala', 4),
  (83, 'Njikoka', 4),
  (84, 'Nnewi North', 4),
  (85, 'Nnewi South', 4),
  (86, 'Ogbaru', 4),
  (87, 'Onitsha North', 4),
  (88, 'Onitsha South', 4),
  (89, 'Orumba North', 4),
  (90, 'Orumba South', 4),
  (91, 'Oyi ', 4),
  (92, 'Alkaleri', 5),
  (93, 'Bauchi', 5),
  (94, 'Bogoro', 5),
  (95, 'Damban', 5),
  (96, 'Darazo', 5),
  (97, 'Dass', 5),
  (98, 'Ganjuwa', 5),
  (99, 'Giade', 5),
  (100, 'Itas/Gadau', 5),
  (101, 'Jama''Are', 5),
  (102, 'Katagum', 5),
  (103, 'Kirfi', 5),
  (104, 'Misau', 5),
  (105, 'Ningi', 5),
  (106, 'Shira', 5),
  (107, 'Tafawa-Balewa', 5),
  (108, 'Toro', 5),
  (109, 'Warji', 5),
  (110, 'Zaki ', 5),
  (111, 'Brass', 32),
  (112, 'Ekeremor', 32),
  (113, 'Kolokuma/Opokuma', 32),
  (114, 'Nembe', 32),
  (115, 'Ogbia', 32),
  (116, 'Sagbama', 32),
  (117, 'Southern Jaw', 32),
  (118, 'Yenegoa ', 32),
  (119, 'Ado', 6),
  (120, 'Agatu', 6),
  (121, 'Apa', 6),
  (122, 'Buruku', 6),
  (123, 'Gboko', 6),
  (124, 'Guma', 6),
  (125, 'Gwer East', 6),
  (126, 'Gwer West', 6),
  (127, 'Katsina-Ala', 6),
  (128, 'Konshisha', 6),
  (129, 'Kwande', 6),
  (130, 'Logo', 6),
  (131, 'Makurdi', 6),
  (132, 'Obi', 6),
  (133, 'Ogbadibo', 6),
  (134, 'Ohimini', 6),
  (135, 'Oju', 6),
  (136, 'Okpokwu', 6),
  (137, 'Oturkpo', 6),
  (138, 'Tarka', 6),
  (139, 'Ukum', 6),
  (140, 'Ushongo', 6),
  (141, 'Vandeikya ', 6),
  (142, 'Abadam', 7),
  (143, 'Askira/Uba', 7),
  (144, 'Bama', 7),
  (145, 'Bayo', 7),
  (146, 'Biu', 7),
  (147, 'Chibok', 7),
  (148, 'Damboa', 7),
  (149, 'Dikwa', 7),
  (150, 'Gubio', 7),
  (151, 'Guzamala', 7),
  (152, 'Gwoza', 7),
  (153, 'Hawul', 7),
  (154, 'Jere', 7),
  (155, 'Kaga', 7),
  (156, 'Kala/Balge', 7),
  (157, 'Konduga', 7),
  (158, 'Kukawa', 7),
  (159, 'Kwaya Kusar', 7),
  (160, 'Mafa', 7),
  (161, 'Magumeri', 7),
  (162, 'Maiduguri', 7),
  (163, 'Marte', 7),
  (164, 'Mobbar', 7),
  (165, 'Monguno', 7),
  (166, 'Ngala', 7),
  (167, 'Nganzai', 7),
  (168, 'Shani ', 7),
  (169, 'Abi', 8),
  (170, 'Akamkpa', 8),
  (171, 'Akpabuyo', 8),
  (172, 'Bakassi', 8),
  (173, 'Bekwara', 8),
  (174, 'Biase', 8),
  (175, 'Boki', 8),
  (176, 'Calabar Municipality', 8),
  (177, 'Calabar South', 8),
  (178, 'Etung', 8),
  (179, 'Ikom', 8),
  (180, 'Obanliku', 8),
  (181, 'Obudu', 8),
  (182, 'Odubra', 8),
  (183, 'Odukpani', 8),
  (184, 'Ogoja', 8),
  (185, 'Yala', 8),
  (186, 'Yarkur', 8),
  (187, 'Aniocha', 9),
  (188, 'Aniocha South', 9),
  (189, 'Bomadi', 9),
  (190, 'Burutu', 9),
  (191, 'Ethiope East', 9),
  (192, 'Ethiope West', 9),
  (193, 'Ika North-East', 9),
  (194, 'Ika South', 9),
  (195, 'Isoko North', 9),
  (196, 'Isoko South', 9),
  (197, 'Ndokwa East', 9),
  (198, 'Ndokwa West', 9),
  (199, 'Okpe', 9),
  (200, 'Oshimili', 9),
  (201, 'Oshimili North', 9),
  (202, 'Patani', 9),
  (203, 'Sapele', 9),
  (204, 'Udu', 9),
  (205, 'Ughelli North', 9),
  (206, 'Ughelli South', 9),
  (207, 'Ukwani', 9),
  (208, 'Uvwie', 9),
  (209, 'Warri Central', 9),
  (210, 'Warri North', 9),
  (211, 'Warri South', 9),
  (212, 'Abakaliki', 37),
  (213, 'Afikpo North', 37),
  (214, 'Afikpo South', 37),
  (215, 'Ebonyi', 37),
  (216, 'Ezza', 37),
  (217, 'Ezza South', 37),
  (218, 'Ishielu', 37),
  (219, 'Ivo ', 37),
  (220, 'Lkwo', 37),
  (221, 'Ohaozara', 37),
  (222, 'Ohaukwu', 37),
  (223, 'Onicha', 37),
  (224, 'Central', 10),
  (225, 'Egor', 10),
  (226, 'Esan Central', 10),
  (227, 'Esan North-East', 10),
  (228, 'Esan South-East ', 10),
  (229, 'Esan West', 10),
  (230, 'Etsako Central', 10),
  (231, 'Etsako East ', 10),
  (232, 'Igueben', 10),
  (233, 'Oredo', 10),
  (234, 'Orhionwon', 10),
  (235, 'Ovia South-East', 10),
  (236, 'Ovia Southwest', 10),
  (237, 'Uhunmwonde', 10),
  (238, 'Ukpoba', 10),
  (239, 'Ado', 36),
  (240, 'Efon', 36),
  (241, 'Ekiti South-West', 36),
  (242, 'Ekiti-East', 36),
  (243, 'Ekiti-West ', 36),
  (244, 'Emure/Ise/Orun', 36),
  (245, 'Gbonyin', 36),
  (246, 'Ido/Osi', 36),
  (247, 'Ijero', 36),
  (248, 'Ikare', 36),
  (249, 'Ikole', 36),
  (250, 'Ilejemeje.', 36),
  (251, 'Irepodun', 36),
  (252, 'Ise/Orun ', 36),
  (253, 'Moba', 36),
  (254, 'Oye', 36),
  (255, 'Aninri', 11),
  (256, 'Enugu Eas', 11),
  (257, 'Enugu North', 11),
  (258, 'Enugu South', 0),
  (259, 'Ezeagu', 11),
  (260, 'Igbo-Ekiti', 11),
  (261, 'Igboeze North', 11),
  (262, 'Igbo-Eze South', 11),
  (263, 'Isi-Uzo', 11),
  (264, 'Nkanu', 11),
  (265, 'Nkanu East', 11),
  (266, 'Nsukka', 11),
  (267, 'Oji-River', 11),
  (268, 'Udenu. ', 11),
  (269, 'Udi Agwu', 11),
  (270, 'Uzo-Uwani', 11),
  (271, 'Abaji', 31),
  (272, 'Abuja Municipal', 31),
  (273, 'Bwari', 31),
  (274, 'Gwagwalada', 31),
  (275, 'Kuje', 31),
  (276, 'Kwali', 31),
  (277, 'Akko', 33),
  (278, 'Balanga', 33),
  (279, 'Billiri', 33),
  (280, 'Dukku', 33),
  (281, 'Funakaye', 33),
  (282, 'Gombe', 33),
  (283, 'Kaltungo', 33),
  (284, 'Kwami', 33),
  (285, 'Nafada/Bajoga ', 33),
  (286, 'Shomgom', 33),
  (287, 'Yamaltu/Delta. ', 33),
  (288, 'Aboh-Mbaise', 12),
  (289, 'Ahiazu-Mbaise', 12),
  (290, 'Ehime-Mbano', 12),
  (291, 'Ezinihitte', 12),
  (292, 'Ideato North', 12),
  (293, 'Ideato South', 12),
  (294, 'Ihitte/Uboma', 12),
  (295, 'Ikeduru', 12),
  (296, 'Isiala Mbano', 12),
  (297, 'Isu', 12),
  (298, 'Mbaitoli', 12),
  (299, 'Mbaitoli', 12),
  (300, 'Ngor-Okpala', 12),
  (301, 'Njaba', 12),
  (302, 'Nkwerre', 12),
  (303, 'Nwangele', 12),
  (304, 'Obowo', 12),
  (305, 'Oguta', 12),
  (306, 'Ohaji/Egbema', 12),
  (307, 'Okigwe', 12),
  (308, 'Orlu', 12),
  (309, 'Orsu', 12),
  (310, 'Oru East', 12),
  (311, 'Oru West', 12),
  (312, 'Owerri North', 12),
  (313, 'Owerri West ', 12),
  (314, 'Owerri-Municipal', 12),
  (315, 'Auyo', 13),
  (316, 'Babura', 13),
  (317, 'Biriniwa', 13),
  (318, 'Birni Kudu', 13),
  (319, 'Buji', 13),
  (320, 'Dutse', 13),
  (321, 'Gagarawa', 13),
  (322, 'Garki', 13),
  (323, 'Gumel', 13),
  (324, 'Guri', 13),
  (325, 'Gwaram', 13),
  (326, 'Gwiwa', 13),
  (327, 'Hadejia', 13),
  (328, 'Jahun', 13),
  (329, 'Kafin Hausa', 13),
  (330, 'Kaugama Kazaure', 13),
  (331, 'Kiri Kasamma', 13),
  (332, 'Kiyawa', 13),
  (333, 'Maigatari', 13),
  (334, 'Malam Madori', 13),
  (335, 'Miga', 13),
  (336, 'Ringim', 13),
  (337, 'Roni', 13),
  (338, 'Sule-Tankarkar', 13),
  (339, 'Taura ', 13),
  (340, 'Yankwashi ', 13),
  (341, 'Birni-Gwari', 15),
  (342, 'Chikun', 15),
  (343, 'Giwa', 15),
  (344, 'Igabi', 15),
  (345, 'Ikara', 15),
  (346, 'Jaba', 15),
  (347, 'Jema''A', 15),
  (348, 'Kachia', 15),
  (349, 'Kaduna North', 15),
  (350, 'Kaduna South', 15),
  (351, 'Kagarko', 15),
  (352, 'Kajuru', 15),
  (353, 'Kaura', 15),
  (354, 'Kauru', 15),
  (355, 'Kubau', 15),
  (356, 'Kudan', 15),
  (357, 'Lere', 15),
  (358, 'Makarfi', 15),
  (359, 'Sabon-Gari', 15),
  (360, 'Sanga', 15),
  (361, 'Soba', 15),
  (362, 'Zango-Kataf', 15),
  (363, 'Zaria ', 15),
  (364, 'Ajingi', 17),
  (365, 'Albasu', 17),
  (366, 'Bagwai', 17),
  (367, 'Bebeji', 17),
  (368, 'Bichi', 17),
  (369, 'Bunkure', 17),
  (370, 'Dala', 17),
  (371, 'Dambatta', 17),
  (372, 'Dawakin Kudu', 17),
  (373, 'Dawakin Tofa', 17),
  (374, 'Doguwa', 17),
  (375, 'Fagge', 17),
  (376, 'Gabasawa', 17),
  (377, 'Garko', 17),
  (378, 'Garum', 17),
  (379, 'Gaya', 17),
  (380, 'Gezawa', 17),
  (381, 'Gwale', 17),
  (382, 'Gwarzo', 17),
  (383, 'Kabo', 17),
  (384, 'Kano Municipal', 17),
  (385, 'Karaye', 17),
  (386, 'Kibiya', 17),
  (387, 'Kiru', 17),
  (388, 'Kumbotso', 17),
  (389, 'Kunchi', 17),
  (390, 'Kura', 17),
  (391, 'Madobi', 17),
  (392, 'Makoda', 17),
  (393, 'Mallam', 17),
  (394, 'Minjibir', 17),
  (395, 'Nasarawa', 17),
  (396, 'Rano', 17),
  (397, 'Rimin Gado', 17),
  (398, 'Rogo', 17),
  (399, 'Shanono', 17),
  (400, 'Sumaila', 17),
  (401, 'Takali', 17),
  (402, 'Tarauni', 17),
  (403, 'Tofa', 17),
  (404, 'Tsanyawa', 17),
  (405, 'Tudun Wada', 17),
  (406, 'Ungogo', 17),
  (407, 'Warawa', 17),
  (408, 'Wudil', 17),
  (409, 'Bakori', 18),
  (410, 'Batagarawa', 18),
  (411, 'Batsari', 18),
  (412, 'Baure', 18),
  (413, 'Bindawa', 18),
  (414, 'Charanchi', 18),
  (415, 'Dan Musa', 18),
  (416, 'Dandume', 18),
  (417, 'Danja', 18),
  (418, 'Daura', 18),
  (419, 'Dutsi', 18),
  (420, 'Dutsin-Ma', 18),
  (421, 'Faskari', 18),
  (422, 'Funtua', 18),
  (423, 'Ingawa', 18),
  (424, 'Jibia', 18),
  (425, 'Kafur', 18),
  (426, 'Kaita', 18),
  (427, 'Kankara', 18),
  (428, 'Kankia', 18),
  (429, 'Katsina', 18),
  (430, 'Kurfi', 18),
  (431, 'Kusada', 18),
  (432, 'Mai''Adua', 18),
  (433, 'Malumfashi', 18),
  (434, 'Mani', 18),
  (435, 'Mashi', 18),
  (436, 'Matazuu', 18),
  (437, 'Musawa', 18),
  (438, 'Rimi', 18),
  (439, 'Sabuwa', 18),
  (440, 'Safana', 18),
  (441, 'Sandamu', 18),
  (442, 'Zango ', 18),
  (443, 'Aleiro', 14),
  (444, 'Arewa-Dandi', 14),
  (445, 'Argungu', 14),
  (446, 'Augie', 14),
  (447, 'Bagudo', 14),
  (448, 'Birnin Kebbi', 14),
  (449, 'Bunza', 14),
  (450, 'Dandi ', 14),
  (451, 'Fakai', 14),
  (452, 'Gwandu', 14),
  (453, 'Jega', 14),
  (454, 'Kalgo ', 14),
  (455, 'Koko/Besse', 14),
  (456, 'Maiyama', 14),
  (457, 'Ngaski', 14),
  (458, 'Sakaba', 14),
  (459, 'Shanga', 14),
  (460, 'Suru', 14),
  (461, 'Wasagu/Danko', 14),
  (462, 'Yauri', 14),
  (463, 'Zuru ', 14),
  (464, 'Adavi', 16),
  (465, 'Ajaokuta', 16),
  (466, 'Ankpa', 16),
  (467, 'Bassa', 16),
  (468, 'Dekina', 16),
  (469, 'Ibaji', 16),
  (470, 'Idah', 16),
  (471, 'Igalamela-Odolu', 16),
  (472, 'Ijumu', 16),
  (473, 'Kabba/Bunu', 16),
  (474, 'Kogi', 16),
  (475, 'Lokoja', 16),
  (476, 'Mopa-Muro', 16),
  (477, 'Ofu', 16),
  (478, 'Ogori/Mangongo', 16),
  (479, 'Okehi', 16),
  (480, 'Okene', 16),
  (481, 'Olamabolo', 16),
  (482, 'Omala', 16),
  (483, 'Yagba East ', 16),
  (484, 'Yagba West', 16),
  (485, 'Asa', 19),
  (486, 'Baruten', 19),
  (487, 'Edu', 19),
  (488, 'Ekiti', 19),
  (489, 'Ifelodun', 19),
  (490, 'Ilorin East', 19),
  (491, 'Ilorin West', 19),
  (492, 'Irepodun', 19),
  (493, 'Isin', 19),
  (494, 'Kaiama', 19),
  (495, 'Moro', 19),
  (496, 'Offa', 19),
  (497, 'Oke-Ero', 19),
  (498, 'Oyun', 19),
  (499, 'Pategi ', 19),
  (500, 'Agege', 20),
  (501, 'Ajeromi-Ifelodun', 20),
  (502, 'Alimosho', 20),
  (503, 'Amuwo-Odofin', 20),
  (504, 'Apapa', 20),
  (505, 'Badagry', 20),
  (506, 'Epe', 20),
  (507, 'Eti-Osa', 20),
  (508, 'Ibeju/Lekki', 20),
  (509, 'Ifako-Ijaye ', 20),
  (510, 'Ikeja', 20),
  (511, 'Ikorodu', 20),
  (512, 'Kosofe', 20),
  (513, 'Lagos Island', 20),
  (514, 'Lagos Mainland', 20),
  (515, 'Mushin', 20),
  (516, 'Ojo', 20),
  (517, 'Oshodi-Isolo', 20),
  (518, 'Shomolu', 20),
  (519, 'Surulere', 20),
  (520, 'Akwanga', 34),
  (521, 'Awe', 34),
  (522, 'Doma', 34),
  (523, 'Karu', 34),
  (524, 'Keana', 34),
  (525, 'Keffi', 34),
  (526, 'Kokona', 34),
  (527, 'Lafia', 34),
  (528, 'Nasarawa', 34),
  (529, 'Nasarawa-Eggon', 34),
  (530, 'Obi', 34),
  (531, 'Toto', 34),
  (532, 'Wamba ', 34),
  (533, 'Agaie', 21),
  (534, 'Agwara', 21),
  (535, 'Bida', 21),
  (536, 'Borgu', 21),
  (537, 'Bosso', 21),
  (538, 'Chanchaga', 21),
  (539, 'Edati', 21),
  (540, 'Gbako', 21),
  (541, 'Gurara', 21),
  (542, 'Katcha', 21),
  (543, 'Kontagora ', 21),
  (544, 'Lapai', 21),
  (545, 'Lavun', 21),
  (546, 'Magama', 21),
  (547, 'Mariga', 21),
  (548, 'Mashegu', 21),
  (549, 'Mokwa', 21),
  (550, 'Muya', 21),
  (551, 'Paikoro', 21),
  (552, 'Rafi', 21),
  (553, 'Rijau', 21),
  (554, 'Shiroro', 21),
  (555, 'Suleja', 21),
  (556, 'Tafa', 21),
  (557, 'Wushishi', 21),
  (558, 'Abeokuta North', 23),
  (559, 'Abeokuta South', 23),
  (560, 'Ado-Odo/Ota', 23),
  (561, 'Egbado North', 23),
  (562, 'Egbado South', 23),
  (563, 'Ewekoro', 23),
  (564, 'Ifo', 23),
  (565, 'Ijebu East', 23),
  (566, 'Ijebu North', 23),
  (567, 'Ijebu North East', 23),
  (568, 'Ijebu Ode', 23),
  (569, 'Ikenne', 23),
  (570, 'Imeko-Afon', 23),
  (571, 'Ipokia', 23),
  (572, 'Obafemi-Owode', 23),
  (573, 'Odeda', 23),
  (574, 'Odogbolu', 23),
  (575, 'Ogun Waterside', 23),
  (576, 'Remo North', 23),
  (577, 'Shagamu', 23),
  (578, 'Akoko North East', 22),
  (579, 'Akoko North West', 22),
  (580, 'Akoko South Akure East', 22),
  (581, 'Akoko South West', 22),
  (582, 'Akure North', 22),
  (583, 'Akure South', 22),
  (584, 'Ese-Odo', 22),
  (585, 'Idanre', 22),
  (586, 'Ifedore', 22),
  (587, 'Ilaje', 22),
  (588, 'Ile-Oluji', 22),
  (589, 'Irele', 22),
  (590, 'Odigbo', 22),
  (591, 'Okeigbo', 22),
  (592, 'Okitipupa', 22),
  (593, 'Ondo East', 22),
  (594, 'Ondo West', 22),
  (595, 'Ose', 22),
  (596, 'Owo ', 22),
  (597, 'Aiyedade', 24),
  (598, 'Aiyedire', 24),
  (599, 'Atakumosa East', 24),
  (600, 'Atakumosa West', 24),
  (601, 'Boluwaduro', 24),
  (602, 'Boripe', 24),
  (603, 'Ede North', 24),
  (604, 'Ede South', 24),
  (605, 'Egbedore', 24),
  (606, 'Ejigbo', 24),
  (607, 'Ife Central', 24),
  (608, 'Ife East', 24),
  (609, 'Ife North', 24),
  (610, 'Ife South', 24),
  (611, 'Ifedayo', 24),
  (612, 'Ifelodun', 24),
  (613, 'Ila', 24),
  (614, 'Ilesha East', 24),
  (615, 'Ilesha West', 24),
  (616, 'Irepodun', 24),
  (617, 'Irewole', 24),
  (618, 'Isokan', 24),
  (619, 'Iwo', 24),
  (620, 'Obokun', 24),
  (621, 'Odo-Otin', 24),
  (622, 'Ola-Oluwa', 24),
  (623, 'Olorunda', 24),
  (624, 'Oriade', 24),
  (625, 'Orolu', 24),
  (626, 'Osogbo', 24),
  (627, 'Afijio', 25),
  (628, 'Akinyele', 25),
  (629, 'Atiba', 25),
  (630, 'Atigbo', 25),
  (631, 'Egbeda', 25),
  (632, 'Ibadan North', 25),
  (633, 'Ibadan North West', 25),
  (634, 'Ibadan South East', 25),
  (635, 'Ibadan South West', 25),
  (636, 'Ibadan Central', 25),
  (637, 'Ibarapa Central', 25),
  (638, 'Ibarapa East', 25),
  (639, 'Ibarapa North', 25),
  (640, 'Ido', 25),
  (641, 'Irepo', 25),
  (642, 'Iseyin', 25),
  (643, 'Itesiwaju', 25),
  (644, 'Iwajowa', 25),
  (645, 'Kajola', 25),
  (646, 'Lagelu Ogbomosho North', 25),
  (647, 'Ogbmosho South', 25),
  (648, 'Ogo Oluwa', 25),
  (649, 'Olorunsogo', 25),
  (650, 'Oluyole', 25),
  (651, 'Ona-Ara', 25),
  (652, 'Orelope', 25),
  (653, 'Ori Ire', 25),
  (654, 'Oyo East', 25),
  (655, 'Oyo West', 25),
  (656, 'Saki East', 25),
  (657, 'Saki West', 25),
  (658, 'Surulere', 25),
  (659, 'Barikin Ladi', 26),
  (660, 'Bassa', 26),
  (661, 'Bokkos', 26),
  (662, 'Jos East', 26),
  (663, 'Jos North', 26),
  (664, 'Jos South', 26),
  (665, 'Kanam', 26),
  (666, 'Kanke', 26),
  (667, 'Langtang North', 26),
  (668, 'Langtang South', 26),
  (669, 'Mangu', 26),
  (670, 'Mikang', 26),
  (671, 'Pankshin', 26),
  (672, 'Qua''An Pan', 26),
  (673, 'Riyom', 26),
  (674, 'Shendam', 26),
  (675, 'Wase', 26),
  (676, 'Abua/Odual', 27),
  (677, 'Ahoada East', 27),
  (678, 'Ahoada West', 27),
  (679, 'Akuku Toru', 27),
  (680, 'Andoni', 27),
  (681, 'Asari-Toru', 27),
  (682, 'Bonny', 27),
  (683, 'Degema', 27),
  (684, 'Eleme', 27),
  (685, 'Emohua', 27),
  (686, 'Etche', 27),
  (687, 'Gokana', 27),
  (688, 'Ikwerre', 27),
  (689, 'Khana', 27),
  (690, 'Obia/Akpor', 27),
  (691, 'Ogba/Egbema/Ndoni', 27),
  (692, 'Ogu/Bolo', 27),
  (693, 'Okrika', 27),
  (694, 'Omumma', 27),
  (695, 'Opobo/Nkoro', 27),
  (696, 'Oyigbo', 27),
  (697, 'Port-Harcourt', 27),
  (698, 'Tai ', 27),
  (699, 'Binji', 28),
  (700, 'Bodinga', 28),
  (701, 'Dange-Shnsi', 28),
  (702, 'Gada', 28),
  (703, 'Gawabawa', 28),
  (704, 'Goronyo', 28),
  (705, 'Gudu', 28),
  (706, 'Illela', 28),
  (707, 'Isa', 28),
  (708, 'Kebbe', 28),
  (709, 'Kware', 28),
  (710, 'Rabah', 28),
  (711, 'Sabon Birni', 28),
  (712, 'Shagari', 28),
  (713, 'Silame', 28),
  (714, 'Sokoto North', 28),
  (715, 'Sokoto South', 28),
  (716, 'Tambuwal', 28),
  (717, 'Tangaza', 28),
  (718, 'Tureta', 28),
  (719, 'Wamako', 28),
  (720, 'Wurno', 28),
  (721, 'Yabo', 28),
  (722, 'Ardo-Kola', 29),
  (723, 'Bali', 29),
  (724, 'Cassol', 29),
  (725, 'Donga', 29),
  (726, 'Gashaka', 29),
  (727, 'Ibi', 29),
  (728, 'Jalingo', 29),
  (729, 'Karin-Lamido', 29),
  (730, 'Kurmi', 29),
  (731, 'Lau', 29),
  (732, 'Sardauna', 29),
  (733, 'Takum', 29),
  (734, 'Ussa', 29),
  (735, 'Wukari', 29),
  (736, 'Yorro', 29),
  (737, 'Zing', 29),
  (738, 'Bade', 30),
  (739, 'Bursari', 30),
  (740, 'Damaturu', 30),
  (741, 'Fika', 30),
  (742, 'Fune', 30),
  (743, 'Geidam', 30),
  (744, 'Gujba', 30),
  (745, 'Gulani', 30),
  (746, 'Jakusko', 30),
  (747, 'Karasuwa', 30),
  (748, 'Karawa', 30),
  (749, 'Machina', 30),
  (750, 'Nangere', 30),
  (751, 'Nguru Potiskum', 30),
  (752, 'Tarmua', 30),
  (753, 'Yunusari', 30),
  (754, 'Yusufari', 30),
  (755, 'Anka ', 35),
  (756, 'Bakura', 35),
  (757, 'Birnin Magaji', 35),
  (758, 'Bukkuyum', 35),
  (759, 'Bungudu', 35),
  (760, 'Gummi', 35),
  (761, 'Gusau', 35),
  (762, 'Kaura', 35),
  (763, 'Maradun', 35),
  (764, 'Maru', 35),
  (765, 'Namoda', 35),
  (766, 'Shinkafi', 35),
  (767, 'Talata Mafara', 35),
  (768, 'Tsafe', 35),
  (769, 'Zurmi ', 35),
  (770, 'Akoko Edo', 10),
  (771, 'Etsako West', 10),
  (772, 'Potiskum', 30),
  (773, 'Owan East', 10),
  (774, 'Ilorin South', 19),
  (775, 'Kazaure', 13),
  (776, 'Gamawa', 5),
  (777, 'Owan West', 10),
  (778, 'Awgu', 11),
  (779, 'Ogbomosho-North', 25),
  (780, 'Yamaltu Deba', 33);

CREATE TABLE IF NOT EXISTS `message_recipients` (
  `message_recipient_id` int(11) NOT NULL,
  `recipient_name` varchar(150) NOT NULL,
  `mobile_number` varchar(15) NOT NULL,
  `email` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `messages` (
  `message_id` int(11) NOT NULL,
  `message` text NOT NULL,
  `message_subject` varchar(20) NOT NULL,
  `sms_count` int(11) NOT NULL,
  `email_count` int(11) NOT NULL,
  `message_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `message_sender` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `order_items` (
  `order_item_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `price` decimal(12,2) NOT NULL,
  `quantity` int(3) NOT NULL DEFAULT '1',
  `item_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `orders` (
  `order_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `sponsor_id` int(11) NOT NULL,
  `academic_term_id` int(11) NOT NULL,
  `process_item_id` int(11) DEFAULT NULL,
  `status_id` int(3) NOT NULL DEFAULT '2'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `process_items` (
  `process_item_id` int(11) NOT NULL,
  `process_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `process_by` int(11) NOT NULL,
  `academic_term_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `relationship_types` (
  `relationship_type_id` int(3) unsigned NOT NULL,
  `relationship_type` varchar(50) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=10 ;

INSERT INTO `relationship_types` (`relationship_type_id`, `relationship_type`) VALUES
  (1, 'Parent'),
  (2, 'Guardian'),
  (3, 'Uncle'),
  (4, 'Aunt'),
  (5, 'Parent''s Employers'),
  (6, 'NGO'),
  (7, 'Government'),
  (8, 'Religious'),
  (9, 'Guardian''s Employers');

CREATE TABLE IF NOT EXISTS `salutations` (
  `salutation_id` int(3) unsigned NOT NULL,
  `salutation_abbr` varchar(10) DEFAULT NULL,
  `salutation_name` varchar(50) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=12 ;

INSERT INTO `salutations` (`salutation_id`, `salutation_abbr`, `salutation_name`) VALUES
  (1, 'Mr.', 'Mister'),
  (2, 'Mrs.', 'Mistress'),
  (3, 'Miss.', 'Miss'),
  (4, 'Prof.', 'Professor'),
  (5, 'Dr.', 'Doctor'),
  (6, 'Chief.', 'Chief'),
  (7, 'Barr.', 'Barrister'),
  (8, 'Engr.', 'Engineer'),
  (9, 'Hon.', 'Honorable'),
  (10, 'Arch.', 'Arch'),
  (11, 'Alh.', 'Alhaji');

CREATE TABLE IF NOT EXISTS `sponsors` (
  `sponsor_id` int(3) unsigned NOT NULL,
  `sponsor_no` varchar(10) NOT NULL,
  `first_name` varchar(50) DEFAULT NULL,
  `other_name` varchar(50) DEFAULT NULL,
  `salutation_id` int(11) DEFAULT NULL,
  `occupation` varchar(70) DEFAULT NULL,
  `company_name` varchar(100) DEFAULT NULL,
  `company_address` text,
  `email` varchar(100) DEFAULT NULL,
  `contact_address` text,
  `local_govt_id` int(11) DEFAULT NULL,
  `state_id` int(11) DEFAULT NULL,
  `country_id` int(11) DEFAULT NULL,
  `mobile_number1` varchar(20) DEFAULT NULL,
  `mobile_number2` varchar(20) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `sponsorship_type_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `sponsorship_types` (
  `sponsorship_type_id` int(3) unsigned NOT NULL,
  `sponsorship_type` varchar(50) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=4 ;

INSERT INTO `sponsorship_types` (`sponsorship_type_id`, `sponsorship_type`) VALUES
  (1, 'Private'),
  (2, 'Corporate'),
  (3, 'Scholarship');

CREATE TABLE IF NOT EXISTS `spouse_details` (
  `spouse_detail_id` int(11) NOT NULL,
  `employee_id` int(5) NOT NULL,
  `spouse_name` varchar(100) NOT NULL,
  `spouse_number` varchar(15) NOT NULL,
  `spouse_employer` varchar(150) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `states` (
  `state_id` int(3) unsigned NOT NULL,
  `state_name` varchar(30) DEFAULT NULL,
  `state_code` varchar(5) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=38 ;

INSERT INTO `states` (`state_id`, `state_name`, `state_code`) VALUES
  (1, 'Abia', 'ABI\r'),
  (2, 'Adamawa', 'ADA\r'),
  (3, 'Akwa Ibom', 'AKW\r'),
  (4, 'Anambra', 'ANA\r'),
  (5, 'Bauchi', 'BAU\r'),
  (6, 'Benue', 'BEN\r'),
  (7, 'Borno', 'BOR\r'),
  (8, 'Cross-River', 'CRO\r'),
  (9, 'Delta', 'DEL\r'),
  (10, 'Edo', 'EDO\r'),
  (11, 'Enugu', 'ENU\r'),
  (12, 'Imo', 'IMO\r'),
  (13, 'Jigawa', 'JIG\r'),
  (14, 'Kebbi', 'KEB\r'),
  (15, 'Kaduna', 'KAD\r'),
  (16, 'Kogi', 'KOG\r'),
  (17, 'Kano', 'KAN\r'),
  (18, 'Katsina', 'KAT\r'),
  (19, 'Kwara', 'KWA\r'),
  (20, 'Lagos', 'LAG\r'),
  (21, 'Niger', 'NIG\r'),
  (22, 'Ondo', 'OND\r'),
  (23, 'Ogun', 'OGU\r'),
  (24, 'Osun', 'OSU\r'),
  (25, 'Oyo', 'OYO\r'),
  (26, 'Plateau', 'PLA\r'),
  (27, 'Rivers', 'RIV\r'),
  (28, 'Sokoto', 'SOK\r'),
  (29, 'Taraba', 'TAR\r'),
  (30, 'Yobe', 'YOB\r'),
  (31, 'FCT', 'FCT\r'),
  (32, 'Bayelsa', 'BAY\r'),
  (33, 'Gombe', 'GOM\r'),
  (34, 'Nasarawa', 'NAS\r'),
  (35, 'Zamfara', 'ZAM\r'),
  (36, 'Ekiti', 'EKI\r'),
  (37, 'Ebonyi', 'EBO\r');

CREATE TABLE IF NOT EXISTS `status` (
  `status_id` int(11) NOT NULL,
  `status` varchar(50) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=3 ;

INSERT INTO `status` (`status_id`, `status`) VALUES
  (1, 'Active'),
  (2, 'Inactive');

CREATE TABLE IF NOT EXISTS `student_feesqueryviews` (
   `order_id` int(11)
  ,`price` decimal(12,2)
  ,`process_item_id` int(11)
  ,`item_id` int(11)
  ,`item_name` varchar(100)
  ,`academic_term_id` int(11)
  ,`academic_term` varchar(50)
  ,`student_name` varchar(152)
  ,`student_id` int(10) unsigned
  ,`sponsor_name` varchar(101)
  ,`sponsor_id` int(3) unsigned
  ,`class_name` varchar(50)
  ,`class_id` int(11)
  ,`classlevel` varchar(50)
  ,`classlevel_id` int(11)
  ,`academic_year_id` int(11)
  ,`academic_year` varchar(50)
  ,`item_type_id` int(11)
  ,`item_status_id` int(3)
  ,`item_type` varchar(50)
);

CREATE TABLE IF NOT EXISTS `student_feesviews` (
   `student_name` varchar(152)
  ,`student_id` int(10) unsigned
  ,`student_no` varchar(50)
  ,`sponsor_name` varchar(101)
  ,`sponsor_id` int(3) unsigned
  ,`salutation_name` varchar(50)
  ,`order_id` int(11)
  ,`price` decimal(12,2)
  ,`quantity` int(3)
  ,`subtotal` decimal(22,2)
  ,`item_id` int(11)
  ,`item_name` varchar(100)
  ,`item_description` text
  ,`academic_term_id` int(11)
  ,`academic_term` varchar(50)
  ,`order_status_id` int(3)
  ,`class_id` int(11)
  ,`class_name` varchar(50)
  ,`classlevel_id` int(11)
  ,`classlevel` varchar(50)
  ,`item_type_id` int(11)
  ,`item_type` varchar(50)
  ,`image_url` varchar(50)
  ,`academic_year_id` int(11) unsigned
  ,`academic_year` varchar(50)
  ,`student_status_id` int(3) unsigned
  ,`student_status` varchar(50)
);
CREATE TABLE IF NOT EXISTS `student_status` (
  `student_status_id` int(3) unsigned NOT NULL,
  `student_status` varchar(50) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=6 ;

INSERT INTO `student_status` (`student_status_id`, `student_status`) VALUES
  (1, 'Active'),
  (2, 'Graduated'),
  (3, 'Suspended'),
  (4, 'Transfered'),
  (5, 'Deceased');

CREATE TABLE IF NOT EXISTS `students` (
  `student_id` int(10) unsigned NOT NULL,
  `sponsor_id` int(11) DEFAULT NULL,
  `first_name` varchar(50) DEFAULT NULL,
  `surname` varchar(50) DEFAULT NULL,
  `other_name` varchar(50) DEFAULT NULL,
  `student_no` varchar(50) DEFAULT NULL,
  `image_url` varchar(50) DEFAULT NULL,
  `gender` varchar(10) DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `religion` varchar(20) DEFAULT NULL,
  `previous_school` text,
  `academic_term_id` int(11) DEFAULT NULL,
  `term_admitted` varchar(50) DEFAULT NULL,
  `student_status_id` int(11) DEFAULT '1',
  `local_govt_id` int(11) DEFAULT NULL,
  `state_id` int(11) NOT NULL,
  `country_id` int(11) unsigned DEFAULT '140',
  `relationtype_id` int(11) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `students_classes` (
  `student_class_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `academic_year_id` int(11) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=58 ;

INSERT INTO `students_classes` (`student_class_id`, `student_id`, `class_id`, `academic_year_id`) VALUES
  (1, 1, 8, 2),
  (2, 3, 9, 2),
  (3, 4, 15, 2),
  (4, 5, 36, 2),
  (5, 6, 106, 2),
  (6, 9, 8, 2),
  (7, 10, 8, 2),
  (8, 11, 9, 2),
  (9, 12, 36, 2),
  (10, 13, 37, 2),
  (11, 14, 8, 2),
  (12, 15, 36, 2),
  (13, 16, 92, 2),
  (14, 17, 87, 2),
  (15, 18, 41, 2),
  (16, 19, 41, 2),
  (17, 20, 15, 2),
  (18, 21, 92, 2),
  (19, 22, 11, 2),
  (20, 24, 78, 2),
  (21, 25, 111, 2),
  (22, 26, 106, 2),
  (23, 27, 86, 2),
  (24, 28, 78, 2),
  (25, 29, 65, 2),
  (26, 30, 108, 2),
  (27, 31, 37, 2),
  (28, 32, 37, 2),
  (29, 33, 87, 2),
  (30, 34, 31, 2),
  (31, 35, 89, 2),
  (32, 36, 99, 2),
  (33, 37, 81, 2),
  (34, 38, 45, 2),
  (35, 39, 79, 2),
  (36, 40, 108, 2),
  (37, 42, 100, 2),
  (38, 43, 106, 2),
  (39, 44, 79, 2),
  (40, 45, 95, 2),
  (41, 46, 92, 2),
  (42, 47, 95, 2),
  (43, 48, 29, 2),
  (44, 49, 110, 2),
  (45, 50, 39, 2),
  (46, 51, 39, 2),
  (47, 52, 51, 2),
  (48, 53, 38, 2),
  (49, 54, 40, 2),
  (50, 55, 96, 2),
  (54, 59, 106, 2),
  (55, 60, 40, 2),
  (56, 61, 10, 2),
  (57, 62, 106, 2);

CREATE TABLE IF NOT EXISTS `students_classlevelviews` (
   `student_name` varchar(152)
  ,`student_no` varchar(50)
  ,`class_name` varchar(50)
  ,`class_id` int(11)
  ,`student_id` int(10) unsigned
  ,`classlevel` varchar(50)
  ,`classlevel_id` int(11)
  ,`sponsor_id` int(11)
  ,`sponsor_name` varchar(101)
  ,`academic_year_id` int(11)
  ,`academic_year` varchar(50)
  ,`student_status_id` int(11)
);

CREATE TABLE IF NOT EXISTS `students_paymentviews` (
   `order_id` int(11)
  ,`academic_term_id` int(11)
  ,`status_id` int(3)
  ,`payment_status` varchar(8)
  ,`academic_term` varchar(50)
  ,`student_name` varchar(152)
  ,`student_no` varchar(50)
  ,`class_name` varchar(50)
  ,`class_id` int(11)
  ,`student_id` int(10) unsigned
  ,`classlevel` varchar(50)
  ,`classlevel_id` int(11)
  ,`sponsor_id` int(11)
  ,`sponsor_name` varchar(101)
  ,`academic_year_id` int(11)
  ,`academic_year` varchar(50)
  ,`student_status_id` int(11)
);

CREATE TABLE IF NOT EXISTS `students_subjectsviews` (
   `student_id` int(11)
  ,`subject_classlevel_id` int(11)
  ,`student_name` varchar(153)
  ,`student_no` varchar(50)
);

CREATE TABLE IF NOT EXISTS `subject_classlevels` (
  `subject_classlevel_id` int(11) NOT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `classlevel_id` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `academic_term_id` int(11) DEFAULT NULL,
  `examstatus_id` int(11) DEFAULT '2'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `subject_classlevelviews` (
   `class_name` varchar(50)
  ,`subject_name` varchar(50)
  ,`subject_id` int(3)
  ,`class_id` int(11)
  ,`classlevel_id` int(11)
  ,`subject_classlevel_id` int(11)
  ,`classlevel` varchar(50)
  ,`examstatus_id` int(11)
  ,`exam_status` varchar(18)
  ,`academic_term_id` int(11)
  ,`academic_term` varchar(50)
  ,`academic_year_id` int(11) unsigned
  ,`academic_year` varchar(50)
);

CREATE TABLE IF NOT EXISTS `subject_groups` (
  `subject_group_id` int(3) NOT NULL,
  `subject_group` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `subject_students_registers` (
  `student_id` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `subject_classlevel_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `subjects` (
  `subject_id` int(3) NOT NULL,
  `subject_name` varchar(50) DEFAULT NULL,
  `subject_group_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `teachers_classes` (
  `teacher_class_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `academic_year_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;
CREATE TABLE IF NOT EXISTS `teachers_classviews` (
   `teacher_class_id` int(11)
  ,`employee_id` int(11)
  ,`class_id` int(11)
  ,`academic_year_id` int(11)
  ,`created_at` datetime
  ,`updated_at` timestamp
  ,`employee_name` varchar(152)
  ,`status_id` int(2)
  ,`class_name` varchar(50)
  ,`classlevel_id` int(11)
  ,`academic_year` varchar(50)
);
CREATE TABLE IF NOT EXISTS `teachers_subjects` (
  `teachers_subjects_id` int(11) NOT NULL,
  `employee_id` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `subject_classlevel_id` int(11) DEFAULT NULL,
  `assign_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;
CREATE TABLE IF NOT EXISTS `teachers_subjectsviews` (
   `teachers_subjects_id` int(11)
  ,`employee_id` int(11)
  ,`class_id` int(11)
  ,`subject_id` int(11)
  ,`subject_name` varchar(50)
  ,`subject_classlevel_id` int(11)
  ,`assign_date` timestamp
  ,`class_name` varchar(50)
  ,`employee_name` varchar(152)
  ,`status_id` int(2)
  ,`academic_term_id` int(11)
  ,`academic_term` varchar(50)
);
CREATE TABLE IF NOT EXISTS `user_roles` (
  `user_role_id` int(3) unsigned NOT NULL,
  `user_role` varchar(50) DEFAULT NULL,
  `group_alias` varchar(30) NOT NULL DEFAULT 'web_users'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

INSERT INTO `user_roles` (`user_role_id`, `user_role`, `group_alias`) VALUES
  (1, 'Sponsor', 'web_users'),
  (2, 'Student', 'web_users'),
  (3, 'Employee', 'emp_users'),
  (4, 'ICT', 'ict_users'),
  (5, 'Admin', 'app_users'),
  (6, 'Super Admin', 'adm_users');

CREATE TABLE IF NOT EXISTS `users` (
  `user_id` int(10) unsigned NOT NULL,
  `username` varchar(70) NOT NULL,
  `password` varchar(150) NOT NULL,
  `display_name` varchar(100) DEFAULT NULL,
  `type_id` int(11) NOT NULL,
  `image_url` varchar(50) NOT NULL,
  `user_role_id` int(11) NOT NULL,
  `group_alias` varchar(20) NOT NULL DEFAULT 'web_users',
  `status_id` int(11) NOT NULL DEFAULT '1',
  `created_by` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=5 ;

INSERT INTO `users` (`user_id`, `username`, `password`, `display_name`, `type_id`, `image_url`, `user_role_id`, `group_alias`, `status_id`, `created_by`, `created_at`, `updated_at`) VALUES
  (1, 'emp0002', '$2a$10$8Jx2GjQqaqqzXfFG1CgCQemp63A2ZZzQbz3z0pv80wat8xNMtDjj.', 'GEORGE, UCHE', 2, 'employees/2.jpg', 6, 'adm_users', 1, 2, '2014-06-16 02:39:58', '2014-10-15 08:09:43'),
  (2, 'spn0001', '$2a$10$BSauz9mo4qbV08gwkX0MUuPtGZ0rMnhy/DkJV6bPmlkbly5MDk7Sa', 'KAYOH, CHINA', 1, 'sponsors/1.jpg', 1, 'web_users', 1, 2, '2014-07-17 11:14:00', '2014-07-21 13:30:13'),
  (3, 'emp0006', '$2a$10$QG2RqGT8ZAMHXaPdEunG4OUcH4Sez52PbRO.DY1jmVvZCj4wrBLcW', 'KINGSLEY, CHINAKA', 6, 'employees/6.JPG', 3, 'emp_users', 1, 2, '2014-10-14 01:43:13', '2014-10-15 08:07:53'),
  (4, 'emp0004', '$2a$10$oncEz7DKJm4EqJUQYn/GmuTpz0JLLaMg.KgqBuKUyM2/vpGkpYXT2', 'BOLA, YUSRAH INUA', 4, 'employees/4.jpg', 4, 'ict_users', 1, 4, '2014-06-24 04:01:20', '2014-10-15 08:10:09');
DROP TABLE IF EXISTS `attend_headerviews`;

CREATE VIEW `attend_headerviews` AS select `a`.`attend_id` AS `attend_id`,`a`.`class_id` AS `class_id`,`a`.`employee_id` AS `employee_id`,`a`.`academic_term_id` AS `academic_term_id`,`a`.`attend_date` AS `attend_date`,`b`.`class_name` AS `class_name`,`b`.`classlevel_id` AS `classlevel_id`,`c`.`academic_term` AS `academic_term`,`c`.`academic_year_id` AS `academic_year_id`,concat(ucase(`d`.`first_name`),' ',`d`.`other_name`) AS `head_tutor` from (((`attends` `a` join `classrooms` `b` on((`a`.`class_id` = `b`.`class_id`))) join `academic_terms` `c` on((`a`.`academic_term_id` = `c`.`academic_term_id`))) join `employees` `d` on((`a`.`employee_id` = `d`.`employee_id`)));
DROP TABLE IF EXISTS `exam_subjectviews`;

CREATE VIEW `exam_subjectviews` AS select `a`.`exam_id` AS `exam_id`,`a`.`exam_desc` AS `exam_desc`,`a`.`class_id` AS `class_id`,`f`.`class_name` AS `class_name`,`c`.`subject_name` AS `subject_name`,`b`.`subject_id` AS `subject_id`,`a`.`subject_classlevel_id` AS `subject_classlevel_id`,`a`.`weightageCA1` AS `weightageCA1`,`a`.`weightageCA2` AS `weightageCA2`,`a`.`weightageExam` AS `weightageExam`,`a`.`employee_id` AS `setup_by`,`a`.`exammarked_status_id` AS `exammarked_status_id`,`a`.`setup_date` AS `setup_date`,`f`.`classlevel_id` AS `classlevel_id`,`g`.`classlevel` AS `classlevel`,`b`.`academic_term_id` AS `academic_term_id`,`d`.`academic_term` AS `academic_term`,`d`.`academic_year_id` AS `academic_year_id`,`e`.`academic_year` AS `academic_year` from (((((`exams` `a` left join (`classlevels` `g` join `classrooms` `f` on((`f`.`classlevel_id` = `g`.`classlevel_id`))) on((`a`.`class_id` = `f`.`class_id`))) join `subject_classlevels` `b` on((`a`.`subject_classlevel_id` = `b`.`subject_classlevel_id`))) join `subjects` `c` on((`b`.`subject_id` = `c`.`subject_id`))) join `academic_terms` `d` on((`b`.`academic_term_id` = `d`.`academic_term_id`))) join `academic_years` `e` on((`d`.`academic_year_id` = `e`.`academic_year_id`)));
DROP TABLE IF EXISTS `examsdetails_reportviews`;

CREATE VIEW `examsdetails_reportviews` AS select `exams`.`exam_id` AS `exam_id`,`subject_classlevels`.`subject_id` AS `subject_id`,`subject_classlevels`.`classlevel_id` AS `classlevel_id`,`classrooms`.`class_id` AS `class_id`,`students`.`student_id` AS `student_id`,`subjects`.`subject_name` AS `subject_name`,`classrooms`.`class_name` AS `class_name`,concat(ucase(`students`.`first_name`),' ',lcase(`students`.`surname`),' ',lcase(`students`.`other_name`)) AS `student_fullname`,`exam_details`.`ca1` AS `ca1`,`exam_details`.`ca2` AS `ca2`,`exam_details`.`exam` AS `exam`,`exams`.`weightageCA1` AS `weightageCA1`,`exams`.`weightageCA2` AS `weightageCA2`,`exams`.`weightageExam` AS `weightageExam`,`academic_terms`.`academic_term_id` AS `academic_term_id`,`academic_terms`.`academic_term` AS `academic_term`,`exams`.`exammarked_status_id` AS `exammarked_status_id`,`academic_terms`.`academic_year_id` AS `academic_year_id`,`academic_years`.`academic_year` AS `academic_year`,`classlevels`.`classlevel` AS `classlevel`,`classlevels`.`classgroup_id` AS `classgroup_id` from (((((((((`exams` join `exam_details` on((`exams`.`exam_id` = `exam_details`.`exam_id`))) join `subject_classlevels` on((`exams`.`subject_classlevel_id` = `subject_classlevels`.`subject_classlevel_id`))) join `subjects` on((`subject_classlevels`.`subject_id` = `subjects`.`subject_id`))) join `students` on((`exam_details`.`student_id` = `students`.`student_id`))) join `academic_terms` on((`subject_classlevels`.`academic_term_id` = `academic_terms`.`academic_term_id`))) join `academic_years` on((`academic_years`.`academic_year_id` = `academic_terms`.`academic_year_id`))) join `classlevels` on((`subject_classlevels`.`classlevel_id` = `classlevels`.`classlevel_id`))) join `students_classes` on((`students`.`student_id` = `students_classes`.`student_id`))) join `classrooms` on((`students_classes`.`class_id` = `classrooms`.`class_id`)));
DROP TABLE IF EXISTS `student_feesqueryviews`;

CREATE VIEW `student_feesqueryviews` AS select `orders`.`order_id` AS `order_id`,`item_bills`.`price` AS `price`,`orders`.`process_item_id` AS `process_item_id`,`item_bills`.`item_id` AS `item_id`,`items`.`item_name` AS `item_name`,`orders`.`academic_term_id` AS `academic_term_id`,`academic_terms`.`academic_term` AS `academic_term`,`students_classlevelviews`.`student_name` AS `student_name`,`students_classlevelviews`.`student_id` AS `student_id`,concat(ucase(`sponsors`.`first_name`),' ',`sponsors`.`other_name`) AS `sponsor_name`,`sponsors`.`sponsor_id` AS `sponsor_id`,`students_classlevelviews`.`class_name` AS `class_name`,`students_classlevelviews`.`class_id` AS `class_id`,`students_classlevelviews`.`classlevel` AS `classlevel`,`students_classlevelviews`.`classlevel_id` AS `classlevel_id`,`students_classlevelviews`.`academic_year_id` AS `academic_year_id`,`students_classlevelviews`.`academic_year` AS `academic_year`,`items`.`item_type_id` AS `item_type_id`,`items`.`item_status_id` AS `item_status_id`,`item_types`.`item_type` AS `item_type` from ((((((`item_types` join `items` on((`item_types`.`item_type_id` = `items`.`item_type_id`))) join `item_bills` on((`item_bills`.`item_id` = `items`.`item_id`))) join `students_classlevelviews` on((`item_bills`.`classlevel_id` = `students_classlevelviews`.`classlevel_id`))) join `sponsors` on((`sponsors`.`sponsor_id` = `students_classlevelviews`.`sponsor_id`))) join `orders` on((`orders`.`student_id` = `students_classlevelviews`.`student_id`))) join `academic_terms` on((`academic_terms`.`academic_term_id` = `orders`.`academic_term_id`)));
DROP TABLE IF EXISTS `student_feesviews`;

CREATE VIEW `student_feesviews` AS select concat(ucase(`a`.`first_name`),' ',`a`.`surname`,' ',`a`.`other_name`) AS `student_name`,`a`.`student_id` AS `student_id`,`a`.`student_no` AS `student_no`,concat(ucase(`b`.`first_name`),' ',`b`.`other_name`) AS `sponsor_name`,`b`.`sponsor_id` AS `sponsor_id`,`c`.`salutation_name` AS `salutation_name`,`f`.`order_id` AS `order_id`,`h`.`price` AS `price`,`h`.`quantity` AS `quantity`,(`h`.`quantity` * `h`.`price`) AS `subtotal`,`h`.`item_id` AS `item_id`,`i`.`item_name` AS `item_name`,`i`.`item_description` AS `item_description`,`f`.`academic_term_id` AS `academic_term_id`,`g`.`academic_term` AS `academic_term`,`f`.`status_id` AS `order_status_id`,`l`.`class_id` AS `class_id`,`m`.`class_name` AS `class_name`,`m`.`classlevel_id` AS `classlevel_id`,`n`.`classlevel` AS `classlevel`,`i`.`item_type_id` AS `item_type_id`,`j`.`item_type` AS `item_type`,`a`.`image_url` AS `image_url`,`g`.`academic_year_id` AS `academic_year_id`,`k`.`academic_year` AS `academic_year`,`d`.`student_status_id` AS `student_status_id`,`d`.`student_status` AS `student_status` from ((((((((((((`students` `a` join `sponsors` `b` on((`a`.`sponsor_id` = `b`.`sponsor_id`))) join `salutations` `c` on((`c`.`salutation_id` = `b`.`salutation_id`))) join `student_status` `d` on((`a`.`student_status_id` = `d`.`student_status_id`))) join `orders` `f` on((`a`.`student_id` = `f`.`student_id`))) join `academic_terms` `g` on((`f`.`academic_term_id` = `g`.`academic_term_id`))) join `order_items` `h` on((`f`.`order_id` = `h`.`order_id`))) join `items` `i` on((`h`.`item_id` = `i`.`item_id`))) join `item_types` `j` on((`i`.`item_type_id` = `j`.`item_type_id`))) join `academic_years` `k` on((`g`.`academic_year_id` = `k`.`academic_year_id`))) join `students_classes` `l` on(((`a`.`student_id` = `l`.`student_id`) and (`g`.`academic_year_id` = `l`.`academic_year_id`)))) join `classrooms` `m` on((`l`.`class_id` = `m`.`class_id`))) join `classlevels` `n` on((`m`.`classlevel_id` = `n`.`classlevel_id`)));
DROP TABLE IF EXISTS `students_classlevelviews`;

CREATE VIEW `students_classlevelviews` AS select concat(ucase(`students`.`first_name`),' ',`students`.`surname`,' ',`students`.`other_name`) AS `student_name`,`students`.`student_no` AS `student_no`,`classrooms`.`class_name` AS `class_name`,`classrooms`.`class_id` AS `class_id`,`students`.`student_id` AS `student_id`,`classlevels`.`classlevel` AS `classlevel`,`classrooms`.`classlevel_id` AS `classlevel_id`,`students`.`sponsor_id` AS `sponsor_id`,concat(ucase(`sponsors`.`first_name`),' ',`sponsors`.`other_name`) AS `sponsor_name`,`students_classes`.`academic_year_id` AS `academic_year_id`,`academic_years`.`academic_year` AS `academic_year`,`students`.`student_status_id` AS `student_status_id` from (((((`students` join `students_classes` on((`students_classes`.`student_id` = `students`.`student_id`))) join `classrooms` on((`students_classes`.`class_id` = `classrooms`.`class_id`))) join `classlevels` on((`classlevels`.`classlevel_id` = `classrooms`.`classlevel_id`))) join `academic_years` on((`students_classes`.`academic_year_id` = `academic_years`.`academic_year_id`))) join `sponsors` on((`students`.`sponsor_id` = `sponsors`.`sponsor_id`)));
DROP TABLE IF EXISTS `students_paymentviews`;

CREATE VIEW `students_paymentviews` AS select `a`.`order_id` AS `order_id`,`a`.`academic_term_id` AS `academic_term_id`,`a`.`status_id` AS `status_id`,(case `a`.`status_id` when 1 then 'Paid' when 2 then 'Not Paid' end) AS `payment_status`,`c`.`academic_term` AS `academic_term`,`b`.`student_name` AS `student_name`,`b`.`student_no` AS `student_no`,`b`.`class_name` AS `class_name`,`b`.`class_id` AS `class_id`,`b`.`student_id` AS `student_id`,`b`.`classlevel` AS `classlevel`,`b`.`classlevel_id` AS `classlevel_id`,`b`.`sponsor_id` AS `sponsor_id`,`b`.`sponsor_name` AS `sponsor_name`,`b`.`academic_year_id` AS `academic_year_id`,`b`.`academic_year` AS `academic_year`,`b`.`student_status_id` AS `student_status_id` from ((`orders` `a` join `students_classlevelviews` `b` on((`a`.`student_id` = `b`.`student_id`))) join `academic_terms` `c` on(((`a`.`academic_term_id` = `c`.`academic_term_id`) and (`c`.`academic_year_id` = `b`.`academic_year_id`)))) where (`a`.`process_item_id` is not null);
DROP TABLE IF EXISTS `students_subjectsviews`;

CREATE VIEW `students_subjectsviews` AS select `a`.`student_id` AS `student_id`,`a`.`subject_classlevel_id` AS `subject_classlevel_id`,concat(ucase(`b`.`first_name`),', ',`b`.`surname`,' ',`b`.`other_name`) AS `student_name`,`b`.`student_no` AS `student_no` from (`subject_students_registers` `a` join `students` `b` on((`a`.`student_id` = `b`.`student_id`)));
DROP TABLE IF EXISTS `subject_classlevelviews`;

CREATE VIEW `subject_classlevelviews` AS select `classrooms`.`class_name` AS `class_name`,`subjects`.`subject_name` AS `subject_name`,`subjects`.`subject_id` AS `subject_id`,`classrooms`.`class_id` AS `class_id`,`classlevels`.`classlevel_id` AS `classlevel_id`,`subject_classlevels`.`subject_classlevel_id` AS `subject_classlevel_id`,`classlevels`.`classlevel` AS `classlevel`,`subject_classlevels`.`examstatus_id` AS `examstatus_id`,(case `subject_classlevels`.`examstatus_id` when 1 then 'Exam Already Setup' when 2 then 'Exam Not Setup' end) AS `exam_status`,`subject_classlevels`.`academic_term_id` AS `academic_term_id`,`academic_terms`.`academic_term` AS `academic_term`,`academic_terms`.`academic_year_id` AS `academic_year_id`,`academic_years`.`academic_year` AS `academic_year` from (((((`subject_classlevels` join `academic_terms` on((`subject_classlevels`.`academic_term_id` = `academic_terms`.`academic_term_id`))) join `academic_years` on((`academic_terms`.`academic_year_id` = `academic_years`.`academic_year_id`))) left join `classrooms` on((`subject_classlevels`.`class_id` = `classrooms`.`class_id`))) left join `classlevels` on((`subject_classlevels`.`classlevel_id` = `classlevels`.`classlevel_id`))) left join `subjects` on((`subject_classlevels`.`subject_id` = `subjects`.`subject_id`)));
DROP TABLE IF EXISTS `teachers_classviews`;

CREATE VIEW `teachers_classviews` AS select `b`.`teacher_class_id` AS `teacher_class_id`,`b`.`employee_id` AS `employee_id`,`b`.`class_id` AS `class_id`,`b`.`academic_year_id` AS `academic_year_id`,`b`.`created_at` AS `created_at`,`b`.`updated_at` AS `updated_at`,concat(ucase(`a`.`first_name`),', ',`a`.`other_name`) AS `employee_name`,`a`.`status_id` AS `status_id`,`c`.`class_name` AS `class_name`,`c`.`classlevel_id` AS `classlevel_id`,`d`.`academic_year` AS `academic_year` from (((`employees` `a` join `teachers_classes` `b` on((`a`.`employee_id` = `b`.`employee_id`))) join `classrooms` `c` on((`b`.`class_id` = `c`.`class_id`))) join `academic_years` `d` on((`b`.`academic_year_id` = `d`.`academic_year_id`)));
DROP TABLE IF EXISTS `teachers_subjectsviews`;

CREATE VIEW `teachers_subjectsviews` AS select `b`.`teachers_subjects_id` AS `teachers_subjects_id`,`b`.`employee_id` AS `employee_id`,`b`.`class_id` AS `class_id`,`d`.`subject_id` AS `subject_id`,`f`.`subject_name` AS `subject_name`,`b`.`subject_classlevel_id` AS `subject_classlevel_id`,`b`.`assign_date` AS `assign_date`,`a`.`class_name` AS `class_name`,concat(ucase(`c`.`first_name`),', ',`c`.`other_name`) AS `employee_name`,`c`.`status_id` AS `status_id`,`d`.`academic_term_id` AS `academic_term_id`,`e`.`academic_term` AS `academic_term` from (((((`classrooms` `a` join `teachers_subjects` `b` on((`a`.`class_id` = `b`.`class_id`))) join `employees` `c` on((`c`.`employee_id` = `b`.`employee_id`))) join `subject_classlevels` `d` on((`d`.`subject_classlevel_id` = `b`.`subject_classlevel_id`))) join `academic_terms` `e` on((`e`.`academic_term_id` = `d`.`academic_term_id`))) join `subjects` `f` on((`f`.`subject_id` = `d`.`subject_id`)));


ALTER TABLE `academic_terms`
ADD PRIMARY KEY (`academic_term_id`), ADD KEY `academic_year_id` (`academic_year_id`), ADD KEY `term_status_id` (`term_status_id`), ADD KEY `term_type_id` (`term_type_id`);

ALTER TABLE `academic_years`
ADD PRIMARY KEY (`academic_year_id`), ADD KEY `year_status_id` (`year_status_id`);

ALTER TABLE `acos`
ADD PRIMARY KEY (`id`);

ALTER TABLE `aros`
ADD PRIMARY KEY (`id`);

ALTER TABLE `aros_acos`
ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `ARO_ACO_KEY` (`aro_id`,`aco_id`);

ALTER TABLE `attend_details`
ADD KEY `student_id` (`student_id`,`attend_id`);

ALTER TABLE `attends`
ADD PRIMARY KEY (`attend_id`), ADD KEY `class_id` (`class_id`,`employee_id`,`academic_term_id`);

ALTER TABLE `classgroups`
ADD PRIMARY KEY (`classgroup_id`);

ALTER TABLE `classlevels`
ADD PRIMARY KEY (`classlevel_id`), ADD KEY `classgroup_id` (`classgroup_id`);

ALTER TABLE `classrooms`
ADD PRIMARY KEY (`class_id`), ADD KEY `classlevel_id` (`classlevel_id`), ADD KEY `class_status_id` (`class_status_id`);

ALTER TABLE `countries`
ADD PRIMARY KEY (`country_id`);

ALTER TABLE `employee_qualifications`
ADD PRIMARY KEY (`employee_qualification_id`);

ALTER TABLE `employee_types`
ADD PRIMARY KEY (`employee_type_id`);

ALTER TABLE `employees`
ADD PRIMARY KEY (`employee_id`);

ALTER TABLE `exam_details`
ADD PRIMARY KEY (`exam_detail_id`);

ALTER TABLE `exams`
ADD PRIMARY KEY (`exam_id`);

ALTER TABLE `grades`
ADD PRIMARY KEY (`grades_id`);

ALTER TABLE `item_bills`
ADD PRIMARY KEY (`item_bill_id`);

ALTER TABLE `item_types`
ADD PRIMARY KEY (`item_type_id`);

ALTER TABLE `item_variables`
ADD PRIMARY KEY (`item_variable_id`);

ALTER TABLE `items`
ADD PRIMARY KEY (`item_id`);

ALTER TABLE `local_govts`
ADD PRIMARY KEY (`local_govt_id`);

ALTER TABLE `message_recipients`
ADD PRIMARY KEY (`message_recipient_id`);

ALTER TABLE `messages`
ADD PRIMARY KEY (`message_id`);

ALTER TABLE `order_items`
ADD PRIMARY KEY (`order_item_id`);

ALTER TABLE `orders`
ADD PRIMARY KEY (`order_id`);

ALTER TABLE `process_items`
ADD PRIMARY KEY (`process_item_id`);

ALTER TABLE `relationship_types`
ADD PRIMARY KEY (`relationship_type_id`);

ALTER TABLE `salutations`
ADD PRIMARY KEY (`salutation_id`);

ALTER TABLE `sponsors`
ADD PRIMARY KEY (`sponsor_id`);

ALTER TABLE `sponsorship_types`
ADD PRIMARY KEY (`sponsorship_type_id`);

ALTER TABLE `spouse_details`
ADD PRIMARY KEY (`spouse_detail_id`);

ALTER TABLE `states`
ADD PRIMARY KEY (`state_id`);

ALTER TABLE `status`
ADD PRIMARY KEY (`status_id`);

ALTER TABLE `student_status`
ADD PRIMARY KEY (`student_status_id`);

ALTER TABLE `students`
ADD PRIMARY KEY (`student_id`);

ALTER TABLE `students_classes`
ADD PRIMARY KEY (`student_class_id`);

ALTER TABLE `subject_classlevels`
ADD PRIMARY KEY (`subject_classlevel_id`);

ALTER TABLE `subject_groups`
ADD PRIMARY KEY (`subject_group_id`);

ALTER TABLE `subjects`
ADD PRIMARY KEY (`subject_id`);

ALTER TABLE `teachers_classes`
ADD PRIMARY KEY (`teacher_class_id`);

ALTER TABLE `teachers_subjects`
ADD PRIMARY KEY (`teachers_subjects_id`);

ALTER TABLE `user_roles`
ADD PRIMARY KEY (`user_role_id`);

ALTER TABLE `users`
ADD PRIMARY KEY (`user_id`), ADD KEY `user_role_id` (`user_role_id`);


ALTER TABLE `academic_terms`
MODIFY `academic_term_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `academic_years`
MODIFY `academic_year_id` int(11) unsigned NOT NULL AUTO_INCREMENT;
ALTER TABLE `acos`
MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=130;
ALTER TABLE `aros`
MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
ALTER TABLE `aros_acos`
MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=40;
ALTER TABLE `attends`
MODIFY `attend_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `classgroups`
MODIFY `classgroup_id` int(11) unsigned NOT NULL AUTO_INCREMENT;
ALTER TABLE `classlevels`
MODIFY `classlevel_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `classrooms`
MODIFY `class_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `countries`
MODIFY `country_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=234;
ALTER TABLE `employee_qualifications`
MODIFY `employee_qualification_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `employee_types`
MODIFY `employee_type_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=8;
ALTER TABLE `employees`
MODIFY `employee_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `exam_details`
MODIFY `exam_detail_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `exams`
MODIFY `exam_id` int(11) unsigned NOT NULL AUTO_INCREMENT;
ALTER TABLE `grades`
MODIFY `grades_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `item_bills`
MODIFY `item_bill_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `item_types`
MODIFY `item_type_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
ALTER TABLE `item_variables`
MODIFY `item_variable_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `items`
MODIFY `item_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `local_govts`
MODIFY `local_govt_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=781;
ALTER TABLE `message_recipients`
MODIFY `message_recipient_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `messages`
MODIFY `message_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `order_items`
MODIFY `order_item_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `orders`
MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `process_items`
MODIFY `process_item_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `relationship_types`
MODIFY `relationship_type_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=10;
ALTER TABLE `salutations`
MODIFY `salutation_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=12;
ALTER TABLE `sponsors`
MODIFY `sponsor_id` int(3) unsigned NOT NULL AUTO_INCREMENT;
ALTER TABLE `sponsorship_types`
MODIFY `sponsorship_type_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
ALTER TABLE `spouse_details`
MODIFY `spouse_detail_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `states`
MODIFY `state_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=38;
ALTER TABLE `status`
MODIFY `status_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
ALTER TABLE `student_status`
MODIFY `student_status_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=6;
ALTER TABLE `students`
MODIFY `student_id` int(10) unsigned NOT NULL AUTO_INCREMENT;
ALTER TABLE `students_classes`
MODIFY `student_class_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=58;
ALTER TABLE `subject_classlevels`
MODIFY `subject_classlevel_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `subject_groups`
MODIFY `subject_group_id` int(3) NOT NULL AUTO_INCREMENT;
ALTER TABLE `subjects`
MODIFY `subject_id` int(3) NOT NULL AUTO_INCREMENT;
ALTER TABLE `teachers_classes`
MODIFY `teacher_class_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `teachers_subjects`
MODIFY `teachers_subjects_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `user_roles`
MODIFY `user_role_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
ALTER TABLE `users`
MODIFY `user_id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=50;