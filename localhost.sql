-- phpMyAdmin SQL Dump
-- version 4.2.7.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Mar 12, 2015 at 11:31 AM
-- Server version: 5.6.20
-- PHP Version: 5.5.15

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `smartedu`
--
DROP DATABASE `smartedu`;
CREATE DATABASE IF NOT EXISTS `smartedu` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `smartedu`;

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_annualClassPositionViews`(IN `ClassID` INT, IN `AcademicYearID` INT)
BEGIN
	#Create a Temporary Table to Hold The Values
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
	
		#Open The Cursor For Iterating Through The Recordset cur1
		OPEN cur1;
			REPEAT
			FETCH cur1 INTO StudentID, StudentName, ClassRoomID, ClassName, YearID, YearName;
				IF NOT done1 THEN	
					BEGIN
						-- Function Call to the records
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
		
			#Open The Cursor For Iterating Through The Recordset cur1
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_assignSubject2Students`(IN `subjectClasslevelID` INT)
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_examsDetailsReportViews`(IN `AcademicID` INT, IN `TypeID` INT)
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
	
		#Open The Cursor For Iterating Through The Recordset cur1
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
	
		#Open The Cursor For Iterating Through The Recordset cur1
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_insertAttendDetails`(IN `AttendID` INT, `StudentIDS` VARCHAR(225))
BEGIN
	# Delete The Record if it exists
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
				# Insert into the attend details table those present
				INSERT INTO attend_details(attend_id, student_id)
				SELECT AttendID, student_id;
		   END LOOP simple_loop;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_insertExamDetails`(IN `ExamID` INT)
BEGIN 
	SELECT class_id, subject_classlevel_id
	INTO @ClassID, @SubjectClasslevelID
	FROM exams
	WHERE exam_id=ExamID LIMIT 1;
		
	# Delete The Record if it exists
	SELECT COUNT(*) INTO @Exist FROM exam_details WHERE exam_id=ExamID;
	IF @Exist > 0 THEN
		BEGIN
			DELETE FROM exam_details WHERE exam_id=ExamID;
		END;
	END IF;
	
	# Insert into the details table
	BEGIN
		INSERT INTO exam_details(exam_id, student_id)
		SELECT	ExamID, student_id
		FROM	subject_students_registers
		WHERE 	class_id=@ClassID AND subject_classlevel_id=@SubjectClasslevelID;
	END;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_processItemVariable`(IN `ItemVariableID` INT)
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
			#Open The Cursor For Iterating Through The Recordset cur1
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_processTerminalFees`(IN `ProcessID` INT)
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_terminalClassPositionViews`(IN `cla_id` INT, IN `term_id` INT)
Block0: BEGIN
	SET @Output = 0;
	#Create a Temporary Table to Hold The Values
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
			#Open The Cursor For Iterating Through The Recordset cur1
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

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `func_annualExamsViews`(`StudentID` INT, `AcademicYearID` INT) RETURNS int(11)
BEGIN
	SET @Output = 0;
	#Create a Temporary Table to Hold The Values
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
			#Open The Cursor For Iterating Through The Recordset cur1
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

CREATE DEFINER=`root`@`localhost` FUNCTION `fun_getAttendSummary`(TermID INT, ClassID INT) RETURNS int(11)
Block0: BEGIN
	SET @Output = 0;
	#Create a Temporary Table to Hold The Values
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

CREATE DEFINER=`root`@`localhost` FUNCTION `fun_getClassHeadTutor`(ClassLevelID INT, YearID INT) RETURNS int(3)
    DETERMINISTIC
Block0: BEGIN
	SET @Output = 0;
	#Create a Temporary Table to Hold The Values
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
	
		#Open The Cursor For Iterating Through The Recordset cur1
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

CREATE DEFINER=`root`@`localhost` FUNCTION `fun_getSubjectClasslevel`(`term_id` INT) RETURNS int(11)
    DETERMINISTIC
Block0: BEGIN
	SET @Output = 0;
	#Create a Temporary Table to Hold The Values
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
	
		#Open The Cursor For Iterating Through The Recordset cur1
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

CREATE DEFINER=`root`@`localhost` FUNCTION `getCurrentTermID`() RETURNS int(11)
BEGIN
	RETURN (SELECT academic_term_id FROM academic_terms WHERE term_status_id=1 LIMIT 1);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getCurrentYearID`() RETURNS int(11)
BEGIN
	RETURN (SELECT academic_year_id FROM academic_years WHERE year_status_id=1 LIMIT 1);	
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `SPLIT_STR`(
	  x VARCHAR(255),
	  delim VARCHAR(12),
	  pos INT
	) RETURNS varchar(255) CHARSET latin1
RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(x, delim, pos),
       LENGTH(SUBSTRING_INDEX(x, delim, pos -1)) + 1),
       delim, '')$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `academic_terms`
--

CREATE TABLE IF NOT EXISTS `academic_terms` (
`academic_term_id` int(11) NOT NULL,
  `academic_term` varchar(50) DEFAULT NULL,
  `academic_year_id` int(11) unsigned DEFAULT NULL,
  `term_status_id` int(11) unsigned DEFAULT NULL,
  `term_type_id` int(11) unsigned DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

--
-- Dumping data for table `academic_terms`
--

INSERT INTO `academic_terms` (`academic_term_id`, `academic_term`, `academic_year_id`, `term_status_id`, `term_type_id`, `created_at`, `updated_at`) VALUES
(1, 'First Term 2013-2014', 1, 2, 1, '2014-06-06 00:00:00', '2014-10-01 17:45:10'),
(2, 'Second Term 2013-2014', 1, 2, 2, '2014-06-06 00:00:00', '2014-10-02 08:57:29'),
(3, 'Third Term 2013-2014', 1, 2, 3, '2014-06-06 00:00:00', '2014-10-01 17:45:10'),
(4, 'First Term 2014-2015', 2, 1, 1, '2014-06-06 00:00:00', '2014-06-05 23:00:00'),
(5, 'Second Term 2014-2015', 2, 2, 2, '2014-06-06 00:00:00', '2014-06-05 23:00:00'),
(6, 'Third Term 2014-2015', 2, 2, 3, '2014-06-06 00:00:00', '2014-06-05 23:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `academic_years`
--

CREATE TABLE IF NOT EXISTS `academic_years` (
`academic_year_id` int(11) unsigned NOT NULL,
  `academic_year` varchar(50) DEFAULT NULL,
  `year_status_id` int(11) unsigned DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=3 ;

--
-- Dumping data for table `academic_years`
--

INSERT INTO `academic_years` (`academic_year_id`, `academic_year`, `year_status_id`, `created_at`, `updated_at`) VALUES
(1, '2013-2014', 2, '2014-06-06 00:00:00', '2014-10-02 09:34:47'),
(2, '2014-2015', 1, '2014-06-06 00:00:00', '2014-06-05 23:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `acos`
--

CREATE TABLE IF NOT EXISTS `acos` (
`id` int(10) NOT NULL,
  `parent_id` int(10) DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `foreign_key` int(10) DEFAULT NULL,
  `alias` varchar(255) DEFAULT NULL,
  `lft` int(10) DEFAULT NULL,
  `rght` int(10) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=144 ;

--
-- Dumping data for table `acos`
--

INSERT INTO `acos` (`id`, `parent_id`, `model`, `foreign_key`, `alias`, `lft`, `rght`) VALUES
(1, NULL, NULL, NULL, 'controllers', 1, 286),
(2, 1, NULL, NULL, 'AcademicTermsController', 2, 5),
(3, 2, NULL, NULL, 'ajax_get_terms', 3, 4),
(4, 1, NULL, NULL, 'AcademicYearsController', 6, 7),
(5, 1, NULL, NULL, 'AppController', 8, 9),
(6, 1, NULL, NULL, 'AssessmentsController', 10, 19),
(7, 6, NULL, NULL, 'index', 11, 12),
(8, 6, NULL, NULL, 'view', 13, 14),
(9, 6, NULL, NULL, 'assess', 15, 16),
(10, 6, NULL, NULL, 'edit', 17, 18),
(11, 1, NULL, NULL, 'AttendsController', 20, 41),
(12, 11, NULL, NULL, 'index', 21, 22),
(13, 11, NULL, NULL, 'search_students', 23, 24),
(14, 11, NULL, NULL, 'take_attend', 25, 26),
(15, 11, NULL, NULL, 'validateIfExist', 27, 28),
(16, 11, NULL, NULL, 'search_attend', 29, 30),
(17, 11, NULL, NULL, 'view', 31, 32),
(18, 11, NULL, NULL, 'edit', 33, 34),
(19, 11, NULL, NULL, 'search_summary', 35, 36),
(20, 11, NULL, NULL, 'summary', 37, 38),
(21, 11, NULL, NULL, 'details', 39, 40),
(22, 1, NULL, NULL, 'ClassroomsController', 42, 55),
(23, 22, NULL, NULL, 'ajax_get_classes', 43, 44),
(24, 22, NULL, NULL, 'index', 45, 46),
(25, 22, NULL, NULL, 'myclass', 47, 48),
(26, 22, NULL, NULL, 'search_classes', 49, 50),
(27, 22, NULL, NULL, 'assign_head_tutor', 51, 52),
(28, 22, NULL, NULL, 'view', 53, 54),
(29, 1, NULL, NULL, 'DashboardController', 56, 73),
(30, 29, NULL, NULL, 'index', 57, 58),
(31, 29, NULL, NULL, 'tutor', 59, 60),
(32, 29, NULL, NULL, 'studentGender', 61, 62),
(33, 29, NULL, NULL, 'studentStauts', 63, 64),
(34, 29, NULL, NULL, 'studentPaymentStatus', 65, 66),
(35, 29, NULL, NULL, 'studentClasslevel', 67, 68),
(36, 29, NULL, NULL, 'classHeadTutor', 69, 70),
(37, 29, NULL, NULL, 'subjectHeadTutor', 71, 72),
(38, 1, NULL, NULL, 'EmployeesController', 74, 91),
(39, 38, NULL, NULL, 'autoComplete', 75, 76),
(40, 38, NULL, NULL, 'validate_form', 77, 78),
(41, 38, NULL, NULL, 'index', 79, 80),
(42, 38, NULL, NULL, 'register', 81, 82),
(43, 38, NULL, NULL, 'view', 83, 84),
(44, 38, NULL, NULL, 'adjust', 85, 86),
(45, 38, NULL, NULL, 'delete', 87, 88),
(46, 38, NULL, NULL, 'statusUpdate', 89, 90),
(47, 1, NULL, NULL, 'ExamsController', 92, 119),
(48, 47, NULL, NULL, 'index', 93, 94),
(49, 47, NULL, NULL, 'setup_exam', 95, 96),
(50, 47, NULL, NULL, 'get_exam_setup', 97, 98),
(51, 47, NULL, NULL, 'search_subjects_assigned', 99, 100),
(52, 47, NULL, NULL, 'search_subjects_examSetup', 101, 102),
(53, 47, NULL, NULL, 'enter_scores', 103, 104),
(54, 47, NULL, NULL, 'view_scores', 105, 106),
(55, 47, NULL, NULL, 'search_student_classlevel', 107, 108),
(56, 47, NULL, NULL, 'term_scorestd', 109, 110),
(57, 47, NULL, NULL, 'term_scorecls', 111, 112),
(58, 47, NULL, NULL, 'annual_scorestd', 113, 114),
(59, 47, NULL, NULL, 'annual_scorecls', 115, 116),
(60, 47, NULL, NULL, 'print_result', 117, 118),
(61, 1, NULL, NULL, 'HomeController', 120, 137),
(62, 61, NULL, NULL, 'index', 121, 122),
(63, 61, NULL, NULL, 'setup', 123, 124),
(64, 61, NULL, NULL, 'students', 125, 126),
(65, 61, NULL, NULL, 'exam', 127, 128),
(66, 61, NULL, NULL, 'search_student', 129, 130),
(67, 61, NULL, NULL, 'term_scorestd', 131, 132),
(68, 61, NULL, NULL, 'annual_scorestd', 133, 134),
(69, 61, NULL, NULL, 'view_stdfees', 135, 136),
(70, 1, NULL, NULL, 'ItemsController', 138, 157),
(71, 70, NULL, NULL, 'index', 139, 140),
(72, 70, NULL, NULL, 'summary', 141, 142),
(73, 70, NULL, NULL, 'payment_status', 143, 144),
(74, 70, NULL, NULL, 'validateIfExist', 145, 146),
(75, 70, NULL, NULL, 'process_fees', 147, 148),
(76, 70, NULL, NULL, 'bill_students', 149, 150),
(77, 70, NULL, NULL, 'view_stdfees', 151, 152),
(78, 70, NULL, NULL, 'view_clsfees', 153, 154),
(79, 70, NULL, NULL, 'statusUpdate', 155, 156),
(80, 1, NULL, NULL, 'LocalGovtsController', 158, 161),
(81, 80, NULL, NULL, 'ajax_get_local_govt', 159, 160),
(82, 1, NULL, NULL, 'MessagesController', 162, 177),
(83, 82, NULL, NULL, 'index', 163, 164),
(84, 82, NULL, NULL, 'recipient', 165, 166),
(85, 82, NULL, NULL, 'delete_recipient', 167, 168),
(86, 82, NULL, NULL, 'send', 169, 170),
(87, 82, NULL, NULL, 'sendOne', 171, 172),
(88, 82, NULL, NULL, 'search_student_classlevel', 173, 174),
(89, 82, NULL, NULL, 'encrypt', 175, 176),
(90, 1, NULL, NULL, 'RecordsController', 178, 201),
(91, 90, NULL, NULL, 'deleteIDs', 179, 180),
(92, 90, NULL, NULL, 'academic_year', 181, 182),
(93, 90, NULL, NULL, 'index', 183, 184),
(94, 90, NULL, NULL, 'class_group', 185, 186),
(95, 90, NULL, NULL, 'class_level', 187, 188),
(96, 90, NULL, NULL, 'class_room', 189, 190),
(97, 90, NULL, NULL, 'subject_group', 191, 192),
(98, 90, NULL, NULL, 'subject', 193, 194),
(99, 90, NULL, NULL, 'grade', 195, 196),
(100, 90, NULL, NULL, 'item', 197, 198),
(101, 90, NULL, NULL, 'item_bill', 199, 200),
(102, 1, NULL, NULL, 'SetupsController', 202, 205),
(103, 102, NULL, NULL, 'setup', 203, 204),
(104, 1, NULL, NULL, 'SponsorsController', 206, 221),
(105, 104, NULL, NULL, 'autoComplete', 207, 208),
(106, 104, NULL, NULL, 'validate_form', 209, 210),
(107, 104, NULL, NULL, 'index', 211, 212),
(108, 104, NULL, NULL, 'register', 213, 214),
(109, 104, NULL, NULL, 'view', 215, 216),
(110, 104, NULL, NULL, 'adjust', 217, 218),
(111, 104, NULL, NULL, 'delete', 219, 220),
(112, 1, NULL, NULL, 'StudentsClassesController', 222, 229),
(113, 112, NULL, NULL, 'assign', 223, 224),
(114, 112, NULL, NULL, 'search', 225, 226),
(115, 112, NULL, NULL, 'search_all', 227, 228),
(116, 1, NULL, NULL, 'StudentsController', 230, 245),
(117, 116, NULL, NULL, 'validate_form', 231, 232),
(118, 116, NULL, NULL, 'index', 233, 234),
(119, 116, NULL, NULL, 'view', 235, 236),
(120, 116, NULL, NULL, 'register', 237, 238),
(121, 116, NULL, NULL, 'adjust', 239, 240),
(122, 116, NULL, NULL, 'delete', 241, 242),
(123, 116, NULL, NULL, 'statusUpdate', 243, 244),
(124, 1, NULL, NULL, 'SubjectsController', 246, 267),
(125, 124, NULL, NULL, 'ajax_get_subjects', 247, 248),
(126, 124, NULL, NULL, 'add2class', 249, 250),
(127, 124, NULL, NULL, 'assign', 251, 252),
(128, 124, NULL, NULL, 'validateIfExist', 253, 254),
(129, 124, NULL, NULL, 'search_all', 255, 256),
(130, 124, NULL, NULL, 'assign_tutor', 257, 258),
(131, 124, NULL, NULL, 'search_assigned', 259, 260),
(132, 124, NULL, NULL, 'modify_assign', 261, 262),
(133, 124, NULL, NULL, 'search_students', 263, 264),
(134, 124, NULL, NULL, 'updateStudentsSubjects', 265, 266),
(135, 1, NULL, NULL, 'UsersController', 268, 285),
(136, 135, NULL, NULL, 'login', 269, 270),
(137, 135, NULL, NULL, 'logout', 271, 272),
(138, 135, NULL, NULL, 'index', 273, 274),
(139, 135, NULL, NULL, 'register', 275, 276),
(140, 135, NULL, NULL, 'forget_password', 277, 278),
(141, 135, NULL, NULL, 'adjust', 279, 280),
(142, 135, NULL, NULL, 'change', 281, 282),
(143, 135, NULL, NULL, 'statusUpdate', 283, 284);

-- --------------------------------------------------------

--
-- Table structure for table `aros`
--

CREATE TABLE IF NOT EXISTS `aros` (
`id` int(10) NOT NULL,
  `parent_id` int(10) DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `foreign_key` int(10) DEFAULT NULL,
  `alias` varchar(255) DEFAULT NULL,
  `lft` int(10) DEFAULT NULL,
  `rght` int(10) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

--
-- Dumping data for table `aros`
--

INSERT INTO `aros` (`id`, `parent_id`, `model`, `foreign_key`, `alias`, `lft`, `rght`) VALUES
(1, NULL, NULL, NULL, 'expired_users', 1, 2),
(2, NULL, NULL, NULL, 'spn_users', 3, 4),
(3, NULL, NULL, NULL, 'emp_users', 5, 6),
(4, NULL, NULL, NULL, 'ict_users', 7, 8),
(5, NULL, NULL, NULL, 'app_users', 9, 10),
(6, NULL, NULL, NULL, 'adm_users', 11, 12);

-- --------------------------------------------------------

--
-- Table structure for table `aros_acos`
--

CREATE TABLE IF NOT EXISTS `aros_acos` (
`id` int(10) NOT NULL,
  `aro_id` int(10) NOT NULL,
  `aco_id` int(10) NOT NULL,
  `_create` varchar(2) NOT NULL DEFAULT '0',
  `_read` varchar(2) NOT NULL DEFAULT '0',
  `_update` varchar(2) NOT NULL DEFAULT '0',
  `_delete` varchar(2) NOT NULL DEFAULT '0'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=45 ;

--
-- Dumping data for table `aros_acos`
--

INSERT INTO `aros_acos` (`id`, `aro_id`, `aco_id`, `_create`, `_read`, `_update`, `_delete`) VALUES
(1, 1, 1, '-1', '-1', '-1', '-1'),
(2, 2, 1, '-1', '-1', '-1', '-1'),
(3, 2, 61, '1', '1', '1', '1'),
(4, 2, 119, '1', '1', '1', '1'),
(5, 2, 109, '1', '1', '1', '1'),
(6, 2, 110, '0', '0', '1', '0'),
(7, 2, 107, '-1', '-1', '-1', '-1'),
(8, 3, 1, '-1', '-1', '-1', '-1'),
(9, 3, 29, '1', '1', '1', '1'),
(10, 3, 47, '1', '1', '1', '1'),
(11, 3, 11, '1', '1', '1', '1'),
(12, 3, 119, '1', '1', '1', '1'),
(13, 3, 25, '1', '1', '1', '1'),
(14, 3, 28, '1', '1', '1', '1'),
(15, 3, 44, '0', '0', '1', '0'),
(16, 4, 1, '-1', '-1', '-1', '-1'),
(17, 4, 29, '1', '1', '1', '1'),
(18, 4, 47, '1', '1', '1', '1'),
(19, 4, 90, '1', '1', '1', '1'),
(20, 4, 11, '1', '1', '1', '1'),
(21, 4, 22, '1', '1', '1', '1'),
(22, 4, 116, '1', '1', '1', '1'),
(23, 4, 118, '1', '1', '1', '1'),
(24, 4, 119, '1', '1', '1', '1'),
(25, 4, 120, '1', '0', '0', '0'),
(26, 4, 121, '0', '0', '1', '0'),
(27, 4, 122, '0', '0', '0', '-1'),
(28, 4, 104, '1', '1', '1', '1'),
(29, 4, 107, '1', '1', '1', '1'),
(30, 4, 109, '1', '1', '1', '1'),
(31, 4, 108, '1', '0', '0', '0'),
(32, 4, 110, '0', '0', '1', '0'),
(33, 4, 111, '0', '0', '0', '-1'),
(34, 4, 38, '1', '1', '1', '1'),
(35, 4, 41, '1', '1', '1', '1'),
(36, 4, 42, '1', '0', '0', '0'),
(37, 4, 44, '0', '0', '1', '0'),
(38, 4, 45, '0', '0', '0', '-1'),
(39, 4, 124, '1', '1', '1', '1'),
(40, 4, 126, '1', '1', '1', '1'),
(41, 4, 70, '1', '1', '1', '1'),
(42, 4, 75, '-1', '-1', '-1', '-1'),
(43, 6, 1, '1', '1', '1', '1'),
(44, 6, 61, '-1', '-1', '-1', '-1');

-- --------------------------------------------------------

--
-- Table structure for table `assessments`
--

CREATE TABLE IF NOT EXISTS `assessments` (
`assessment_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `academic_term_id` int(11) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=4 ;

--
-- Dumping data for table `assessments`
--

INSERT INTO `assessments` (`assessment_id`, `student_id`, `academic_term_id`) VALUES
(1, 3, 4),
(2, 5, 4),
(3, 15, 4);

-- --------------------------------------------------------

--
-- Table structure for table `attend_details`
--

CREATE TABLE IF NOT EXISTS `attend_details` (
  `student_id` int(11) DEFAULT NULL,
  `attend_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `attend_details`
--

INSERT INTO `attend_details` (`student_id`, `attend_id`) VALUES
(3, 15),
(3, 16),
(5, 1),
(5, 5),
(5, 14),
(5, 17),
(5, 18),
(5, 19),
(11, 15),
(12, 1),
(12, 2),
(12, 14),
(12, 17),
(15, 2),
(15, 17),
(15, 19),
(18, 4),
(19, 4),
(51, 13);

-- --------------------------------------------------------

--
-- Stand-in structure for view `attend_headerviews`
--
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
-- --------------------------------------------------------

--
-- Table structure for table `attends`
--

CREATE TABLE IF NOT EXISTS `attends` (
`attend_id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `academic_term_id` int(11) NOT NULL,
  `attend_date` date NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=20 ;

--
-- Dumping data for table `attends`
--

INSERT INTO `attends` (`attend_id`, `class_id`, `employee_id`, `academic_term_id`, `attend_date`) VALUES
(1, 36, 2, 4, '2014-10-22'),
(2, 36, 2, 4, '2014-10-20'),
(3, 9, 2, 4, '2014-10-20'),
(4, 41, 6, 4, '2014-10-21'),
(5, 36, 2, 4, '2014-10-21'),
(13, 39, 6, 4, '2014-10-21'),
(14, 36, 2, 4, '2014-11-05'),
(15, 9, 2, 4, '2014-11-05'),
(16, 9, 2, 4, '2014-11-04'),
(17, 36, 2, 4, '2014-11-04'),
(18, 36, 2, 4, '2014-11-10'),
(19, 36, 2, 4, '2014-11-13');

-- --------------------------------------------------------

--
-- Table structure for table `classgroups`
--

CREATE TABLE IF NOT EXISTS `classgroups` (
`classgroup_id` int(11) unsigned NOT NULL,
  `classgroup` varchar(50) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

--
-- Dumping data for table `classgroups`
--

INSERT INTO `classgroups` (`classgroup_id`, `classgroup`) VALUES
(1, 'Pre-Nursery'),
(2, 'Nursery'),
(3, 'Junior Primary'),
(4, 'Senior Primary'),
(5, 'JSS'),
(6, 'SSS');

-- --------------------------------------------------------

--
-- Table structure for table `classlevels`
--

CREATE TABLE IF NOT EXISTS `classlevels` (
`classlevel_id` int(11) NOT NULL,
  `classlevel` varchar(50) DEFAULT NULL,
  `classgroup_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=17 ;

--
-- Dumping data for table `classlevels`
--

INSERT INTO `classlevels` (`classlevel_id`, `classlevel`, `classgroup_id`) VALUES
(1, 'Playclass', 1),
(2, 'Reception', 1),
(3, 'Nursery 1', 2),
(4, 'Nursery 2', 2),
(5, 'Primary 1', 3),
(6, 'Primary 2', 3),
(7, 'Primary 3', 3),
(8, 'Primary 4', 4),
(9, 'Primary 5', 4),
(10, 'Primary 6', 4),
(11, 'JSS 1', 5),
(12, 'JSS 2', 5),
(13, 'JSS 3', 5),
(14, 'SSS 1', 6),
(15, 'SSS 2', 6),
(16, 'SSS 3', 6);

-- --------------------------------------------------------

--
-- Table structure for table `classrooms`
--

CREATE TABLE IF NOT EXISTS `classrooms` (
`class_id` int(11) NOT NULL,
  `class_name` varchar(50) DEFAULT NULL,
  `classlevel_id` int(11) DEFAULT NULL,
  `class_size` int(11) DEFAULT NULL,
  `class_status_id` int(3) DEFAULT '1'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=113 ;

--
-- Dumping data for table `classrooms`
--

INSERT INTO `classrooms` (`class_id`, `class_name`, `classlevel_id`, `class_size`, `class_status_id`) VALUES
(1, 'Play class A', 1, 50, 1),
(2, 'Play class B', 1, 50, 1),
(3, 'Play class C', 1, 50, 1),
(4, 'Play class D', 1, 50, 1),
(5, 'Play class E', 1, 50, 1),
(6, 'Play class F', 1, 50, 1),
(7, 'Play class G', 1, 50, 1),
(8, 'Reception A', 2, 50, 1),
(9, 'Reception B', 2, 50, 1),
(10, 'Reception C', 2, 50, 1),
(11, 'Reception D', 2, 50, 1),
(12, 'Reception E', 2, 50, 1),
(13, 'Reception F', 2, 50, 1),
(14, 'Reception G', 2, 50, 1),
(15, 'Nursery 1 A', 3, 50, 1),
(16, 'Nursery 1 B', 3, 50, 1),
(17, 'Nursery 1 C', 3, 50, 1),
(18, 'Nursery 1 D', 3, 50, 1),
(19, 'Nursery 1 E', 3, 50, 1),
(20, 'Nursery 1 F', 3, 50, 1),
(21, 'Nursery 1 G', 3, 50, 1),
(22, 'Nursery 2 A', 4, 50, 1),
(23, 'Nursery 2 B', 4, 50, 1),
(24, 'Nursery 2 C', 4, 50, 1),
(25, 'Nursery 2 D', 4, 50, 1),
(26, 'Nursery 2 E', 4, 50, 1),
(27, 'Nursery 2 F', 4, 50, 1),
(28, 'Nursery 2 G', 4, 50, 1),
(29, 'Primary 1 A', 5, 50, 1),
(30, 'Primary 1 B', 5, 50, 1),
(31, 'Primary 1 C', 5, 50, 1),
(32, 'Primary 1 D', 5, 50, 1),
(33, 'Primary 1 E', 5, 50, 1),
(34, 'Primary 1 F', 5, 50, 1),
(35, 'Primary 1 G', 5, 50, 1),
(36, 'Primary 2 A', 6, 50, 1),
(37, 'Primary 2 B', 6, 50, 1),
(38, 'Primary 2 C', 6, 50, 1),
(39, 'Primary 2 D', 6, 50, 1),
(40, 'Primary 2 E', 6, 50, 1),
(41, 'Primary 2 F', 6, 50, 1),
(42, 'Primary 2 G', 6, 50, 1),
(43, 'Primary 3 A', 7, 50, 1),
(44, 'Primary 3 B', 7, 50, 1),
(45, 'Primary 3 C', 7, 50, 1),
(46, 'Primary 3 D', 7, 50, 1),
(47, 'Primary 3 E', 7, 50, 1),
(48, 'Primary 3 F', 7, 50, 1),
(49, 'Primary 3 G', 7, 50, 1),
(50, 'Primary 4 A', 8, 50, 1),
(51, 'Primary 4 B', 8, 50, 1),
(52, 'Primary 4 C', 8, 50, 1),
(53, 'Primary 4 D', 8, 50, 1),
(54, 'Primary 4 E', 8, 50, 1),
(55, 'Primary 4 F', 8, 50, 1),
(56, 'Primary 4 G', 8, 50, 1),
(57, 'Primary 5 A', 9, 50, 1),
(58, 'Primary 5 B', 9, 50, 1),
(59, 'Primary 5 C', 9, 50, 1),
(60, 'Primary 5 D', 9, 50, 1),
(61, 'Primary 5 E', 9, 50, 1),
(62, 'Primary 5 F', 9, 50, 1),
(63, 'Primary 5 G', 9, 50, 1),
(64, 'Primary 6 A', 10, 50, 1),
(65, 'Primary 6 B', 10, 50, 1),
(66, 'Primary 6 C', 10, 50, 1),
(67, 'Primary 6 D', 10, 50, 1),
(68, 'Primary 6 E', 10, 50, 1),
(69, 'Primary 6 F', 10, 50, 1),
(70, 'Primary 6 G', 10, 50, 1),
(71, 'JSS 1 A', 11, 50, 1),
(72, 'JSS 1 B', 11, 50, 1),
(73, 'JSS 1 C', 11, 50, 1),
(74, 'JSS 1 D', 11, 50, 1),
(75, 'JSS 1 E', 11, 50, 1),
(76, 'JSS 1 F', 11, 50, 1),
(77, 'JSS 1 G', 11, 50, 1),
(78, 'JSS 2 A', 12, 50, 1),
(79, 'JSS 2 B', 12, 50, 1),
(80, 'JSS 2 C', 12, 50, 1),
(81, 'JSS 2 D', 12, 50, 1),
(82, 'JSS 2 E', 12, 50, 1),
(83, 'JSS 2 F', 12, 50, 1),
(84, 'JSS 2 G', 12, 50, 1),
(85, 'JSS 3 A', 13, 50, 1),
(86, 'JSS 3 B', 13, 50, 1),
(87, 'JSS 3 C', 13, 50, 1),
(88, 'JSS 3 D', 13, 50, 1),
(89, 'JSS 3 E', 13, 50, 1),
(90, 'JSS 3 F', 13, 50, 1),
(91, 'JSS 3 G', 13, 50, 1),
(92, 'SSS 1 A', 14, 50, 1),
(93, 'SSS 1 B', 14, 50, 1),
(94, 'SSS 1 C', 14, 50, 1),
(95, 'SSS 1 D', 14, 50, 1),
(96, 'SSS 1 E', 14, 50, 1),
(97, 'SSS 1 F', 14, 50, 1),
(98, 'SSS 1 G', 14, 50, 1),
(99, 'SSS 2 A', 15, 50, 1),
(100, 'SSS 2 B', 15, 50, 1),
(101, 'SSS 2 C', 15, 50, 1),
(102, 'SSS 2 D', 15, 50, 1),
(103, 'SSS 2 E', 15, 50, 1),
(104, 'SSS 2 F', 15, 50, 1),
(105, 'SSS 2 G', 15, 50, 1),
(106, 'SSS 3 A', 16, 50, 1),
(107, 'SSS 3 B', 16, 50, 1),
(108, 'SSS 3 C', 16, 50, 1),
(109, 'SSS 3 D', 16, 50, 1),
(110, 'SSS 3 E', 16, 50, 1),
(111, 'SSS 3 F', 16, 50, 1),
(112, 'SSS 3 G', 16, 50, 1);

-- --------------------------------------------------------

--
-- Table structure for table `countries`
--

CREATE TABLE IF NOT EXISTS `countries` (
`country_id` int(3) unsigned NOT NULL,
  `country_name` varchar(50) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=234 ;

--
-- Dumping data for table `countries`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `employee_qualifications`
--

CREATE TABLE IF NOT EXISTS `employee_qualifications` (
`employee_qualification_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `institution` text NOT NULL,
  `qualification` varchar(150) DEFAULT NULL,
  `date_from` date DEFAULT NULL,
  `date_to` date DEFAULT NULL,
  `qualification_date` date DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=13 ;

--
-- Dumping data for table `employee_qualifications`
--

INSERT INTO `employee_qualifications` (`employee_qualification_id`, `employee_id`, `institution`, `qualification`, `date_from`, `date_to`, `qualification_date`) VALUES
(1, 15, 'St. Bath Nur / Pri School, Zaria, Kaduna State', 'Credit', '1990-06-20', '1999-08-12', '1999-08-25'),
(2, 15, 'St. Bath Secondary School, Zaria, Kaduna State', 'WAEC Certificate', '1999-09-22', '2005-09-28', '2005-09-29'),
(3, 15, 'Kaduna State University', 'B.Sc. Maths / Second Class Upper', '2008-11-11', '2012-10-30', '2012-11-08'),
(4, 16, '1st Baptist High, Bata, Kano', 'W.A.E.C', '1998-08-25', '2004-09-21', '2004-11-25'),
(5, 16, '2nd Baptist High, Sobon Gari, Kaduna', 'W.A.E.C', '2014-10-07', '2014-10-17', '2014-10-29'),
(7, 16, 'ABU Zaria', 'B.Sc.', '2014-10-05', '2014-10-29', '2014-11-07'),
(8, 16, 'BUK Kano', 'M.Sc. In View', '2014-10-22', NULL, NULL),
(9, 20, 'Zaria Children Children', 'School Certificate', '2000-10-12', '2009-11-12', '2009-11-19'),
(10, 6, 'Depot N.A', 'School Certificate', '1991-05-15', '1998-08-12', '1998-09-08'),
(11, 4, '', '', NULL, NULL, NULL),
(12, 4, '', '', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `employee_types`
--

CREATE TABLE IF NOT EXISTS `employee_types` (
`employee_type_id` int(11) unsigned NOT NULL,
  `employee_type` varchar(100) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=8 ;

--
-- Dumping data for table `employee_types`
--

INSERT INTO `employee_types` (`employee_type_id`, `employee_type`) VALUES
(1, 'Applicants'),
(2, 'Auxiliary'),
(3, 'Contract'),
(4, 'Corper/IT'),
(5, 'OutSourced Staffs'),
(6, 'Permanent'),
(7, 'Retired/Pension');

-- --------------------------------------------------------

--
-- Table structure for table `employees`
--

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=21 ;

--
-- Dumping data for table `employees`
--

INSERT INTO `employees` (`employee_id`, `employee_no`, `salutation_id`, `first_name`, `other_name`, `gender`, `birth_date`, `image_url`, `contact_address`, `employee_type_id`, `mobile_number1`, `mobile_number2`, `marital_status`, `country_id`, `state_id`, `local_govt_id`, `email`, `next_ofkin_name`, `next_ofkin_number`, `next_ofkin_relate`, `form_of_identity`, `identity_no`, `identity_expiry_date`, `status_id`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'emp0001', 7, 'John', 'Igwe Chukwudi', 'male', '1991-03-04', 'employees/1.jpg', 'No 15 Major Ahmed Avenue, Asaba, Delta State', 6, '07032563781', '', 'Single', 140, 0, 73, 'chukwu@gmail.com', NULL, NULL, NULL, '', '', '0000-00-00', 1, 1, '2014-06-24 03:53:30', '2015-01-10 19:50:03'),
(2, 'emp0002', 9, 'George', 'Uche', 'male', '1990-05-08', 'employees/2.jpg', 'CBN Quarters Wuse II FCT, Abuja', 6, '08030734377', '08037483829', 'Married', 140, 1, 6, 'uche@yahoo.com', NULL, NULL, NULL, '', '', '0000-00-00', 2, 1, '2014-06-24 03:56:22', '2015-01-10 19:50:20'),
(3, 'emp0003', 4, 'Yahuza', 'Sule Musa', 'male', '1972-05-10', NULL, 'No 11 Mallam Kato Square S/G, Kano ', 3, '08037263872', '09038364822', 'Married', 140, 2, 23, 'sule@gmail.com', NULL, NULL, NULL, '', '', '0000-00-00', 1, 1, '2014-06-24 03:58:42', '2015-01-10 19:50:06'),
(4, 'emp0004', 2, 'Bola', 'Yusrah Inua', 'Female', '1990-09-08', 'employees/4.jpg', 'Kilometer 22 Funtua, Katsina', 2, '08174827455', '09038364822', 'Married', 140, 32, 115, 'inua@hotmail.co.za', 'Mallam Inua', '09038956758', 'Uncle', 'National I.D Card', '234565534', '2015-03-27', 1, 1, '2014-06-24 04:01:20', '2015-03-12 09:05:00'),
(5, 'emp0005', 1, 'KayOh', 'Chi Odi', 'male', '1992-11-12', 'employees/5.jpg', '22 Calabari Street Ebute Meta Lagos', 5, '07032563781', '', 'Single', 142, 11, 267, 'chichi@rocketmail.co', NULL, NULL, NULL, '', '', '0000-00-00', 1, 1, '2014-06-25 01:59:05', '2014-06-25 00:59:05'),
(6, 'emp0006', 1, 'Kingsley', 'Chinaka', 'Female', '2014-07-15', 'employees/6.JPG', 'No 10 Igbo Road S/G Zaira', 6, '08030734377', '08022020075', 'Single', 140, 12, 290, 'kingsley4united@yahoo.com', 'Mr. George', '08174949450', 'Brother', 'National I.D Card', '7865798', '2018-02-14', 1, 2, '2014-07-15 12:57:59', '2015-02-05 10:35:07'),
(7, 'emp0007', 1, 'Okon', 'Ubong', 'male', '1982-07-13', 'employees/7.JPG', 'Zaria Academy Quarters Shika, Zaria', 6, '07034825391', '', 'Married', 140, 8, 179, 'okon@yahoo.com', NULL, NULL, NULL, '', '', '0000-00-00', 1, 2, '2014-09-04 09:21:15', '2014-09-04 08:21:15'),
(8, 'emp0008', 11, 'Juniadu', 'Salihu', 'male', '1975-10-14', 'employees/8.JPG', 'ABU Quarters A.B.U Samaru Zaria', 3, '09028364974', '07012356473', 'Married', 140, 18, 412, 'salihu@gmail.com', NULL, NULL, NULL, '', '', '0000-00-00', 1, 2, '2014-09-04 09:25:26', '2014-09-04 08:25:26'),
(9, 'emp0009', 3, 'Ijeoma', 'Duru Okoh', 'female', '1982-03-22', 'employees/9.JPG', 'No 77 Itire Road Surulere, Lagos', 6, '08028398573', '07032184894', 'Married', 140, 9, 187, 'ijeoma@yahoo.co.uk', NULL, NULL, NULL, '', '', '0000-00-00', 1, 2, '2014-09-04 09:28:36', '2014-09-04 08:28:36'),
(10, 'emp0010', 6, 'Paul', 'Chukwu Igwe', 'male', '2014-08-10', '10.jpg', 'NYSC Secretariat Ibadan North LGA', 3, '08139516789', '', 'Married', 140, 1, 3, 'chukwu@gmail.com', NULL, NULL, NULL, '', '', '0000-00-00', 1, 2, '2014-10-08 03:43:30', '2014-10-24 08:56:58'),
(11, 'emp0011', 6, 'John', 'Emmanuel', 'male', '1985-05-09', 'employees/11.jpg', 'CBN Quaters', 2, '090284657893', '34567879765', 'Single', 140, 6, 119, 'joel@ymail.com', NULL, NULL, NULL, '', '', '0000-00-00', 1, 2, '2014-10-24 10:38:09', '2014-10-24 09:52:39'),
(13, 'emp0013', 10, 'Joel', 'Emma', 'male', '1985-09-05', 'employees/13.jpg', 'CBN Quaters', 2, '090284657893', '34567879765', 'Single', 140, 6, 119, 'joel@ymail.com', NULL, NULL, NULL, '', '', '0000-00-00', 1, 2, '2014-10-24 10:46:12', '2014-10-24 09:46:12'),
(14, 'emp0014', 6, 'Okon', 'Udoh', 'male', '2014-10-26', NULL, 'CHLETECH Zaria', NULL, '08139516789', '34567879765', 'Married', 140, 37, 212, 'okon@ymail.com', NULL, NULL, NULL, '', '', '0000-00-00', 1, 2, '2014-10-26 01:38:42', '2014-10-26 12:38:42'),
(15, 'emp0015', 6, 'Jude', 'Eze Ebunafor', 'male', '1955-02-25', 'employees/15.jpg', 'K/M 24, Lagos-Badagry Express Way, Lagos', NULL, '08058472593', '09474853738', 'Married', 140, 1, 3, 'judeemma@yahoo.com', 'Mrs. Judith Eze Ebunafor', '08049504784', 'Wife', 'National I.D Card', '048595639478', '2016-05-03', 1, 2, '2014-10-27 07:10:06', '2014-10-27 18:10:07'),
(16, 'emp0016', 7, 'Mary', 'Jane', 'female', '1983-08-16', 'employees/16.jpg', 'First Bank Quaters Lagos', NULL, '08058472593', '09474853738', 'Married', 140, 37, 212, 'okon@ymail.com', 'Moses Mark', '98764786549867', 'Brother', 'Drivers Licence', '34567897435', '2015-07-27', 1, 2, '2014-10-27 07:23:56', '2014-10-27 18:23:56'),
(19, 'emp0019', 11, 'Sulieman', 'Bala Audu', 'male', '1970-01-01', NULL, '345 dogon Bauchi Road S/G Zaria', NULL, '07034825391', '', 'Married', 140, 13, 315, 'kheengz@gmail.com', 'Mr. & Mrs Ibrahim Juniadu', '08136583745', 'Parent', '', '', '1970-01-01', 1, 2, '2014-10-27 07:40:14', '2014-10-27 19:58:36'),
(20, 'emp0020', 5, 'Attama', 'Benjamin', 'Male', '2014-10-29', 'employees/20.jpg', 'Sokoto Road, Zaria', NULL, '08030734377', '07033456863', 'Single', 140, 15, 363, 'kingsley4united@yahoo.com', 'Mr. Mrs Atama', '08134857694', 'Parent', '', '', NULL, 2, 2, '2014-10-29 02:51:01', '2014-10-29 15:31:55');

-- --------------------------------------------------------

--
-- Table structure for table `exam_details`
--

CREATE TABLE IF NOT EXISTS `exam_details` (
`exam_detail_id` int(11) NOT NULL,
  `exam_id` int(11) DEFAULT NULL,
  `student_id` int(11) DEFAULT NULL,
  `ca1` decimal(4,1) DEFAULT '0.0',
  `ca2` decimal(4,1) DEFAULT '0.0',
  `exam` decimal(4,1) DEFAULT '0.0'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=72 ;

--
-- Dumping data for table `exam_details`
--

INSERT INTO `exam_details` (`exam_detail_id`, `exam_id`, `student_id`, `ca1`, `ca2`, `exam`) VALUES
(1, 4, 6, '15.0', '28.0', '42.0'),
(2, 5, 1, '10.0', '13.0', '35.0'),
(3, 5, 9, '2.0', '16.0', '26.0'),
(4, 5, 10, '11.0', '20.0', '22.0'),
(5, 5, 11, '7.0', '15.0', '7.0'),
(6, 5, 14, '14.0', '22.0', '44.0'),
(7, 6, 1, '28.0', '18.0', '44.0'),
(8, 6, 9, '28.0', '22.0', '55.0'),
(9, 6, 10, '12.0', '20.0', '42.0'),
(10, 6, 11, '5.0', '21.0', '35.0'),
(11, 6, 14, '28.0', '18.0', '42.0'),
(12, 6, 22, '14.0', '24.0', '33.0'),
(13, 7, 1, '8.0', '22.0', '25.0'),
(14, 7, 9, '22.0', '24.0', '55.0'),
(15, 7, 10, '17.0', '19.0', '47.0'),
(16, 7, 11, '20.0', '17.0', '50.0'),
(17, 7, 14, '11.0', '22.0', '33.0'),
(18, 7, 22, '16.0', '17.0', '23.0'),
(19, 8, 1, '20.0', '11.0', '40.0'),
(20, 8, 9, '10.0', '12.0', '30.0'),
(21, 8, 10, '25.0', '23.0', '64.0'),
(22, 8, 11, '15.0', '19.0', '50.0'),
(23, 8, 14, '21.0', '22.0', '55.0'),
(24, 8, 22, '5.0', '11.0', '44.0'),
(26, 9, 1, '15.0', '12.0', '35.0'),
(27, 9, 9, '5.0', '19.0', '26.0'),
(28, 9, 10, '14.0', '15.0', '22.0'),
(29, 9, 11, '7.0', '15.0', '7.0'),
(30, 9, 14, '14.0', '25.0', '48.0'),
(31, 10, 1, '24.0', '15.0', '44.0'),
(32, 10, 9, '28.0', '24.0', '52.0'),
(33, 10, 10, '12.0', '20.0', '42.0'),
(34, 10, 11, '5.0', '21.0', '35.0'),
(35, 10, 14, '28.0', '18.0', '42.0'),
(36, 10, 22, '11.0', '22.0', '33.0'),
(37, 11, 1, '8.0', '22.0', '25.0'),
(38, 11, 9, '22.0', '24.0', '55.0'),
(39, 11, 10, '17.0', '22.0', '47.0'),
(40, 11, 11, '20.0', '17.0', '46.0'),
(41, 11, 14, '11.0', '25.0', '31.0'),
(42, 11, 22, '16.0', '17.0', '22.0'),
(43, 12, 1, '20.0', '13.0', '40.0'),
(44, 12, 9, '10.0', '12.0', '34.0'),
(45, 12, 10, '25.0', '23.0', '61.0'),
(46, 12, 11, '15.0', '17.0', '53.0'),
(47, 12, 14, '21.0', '22.0', '55.0'),
(48, 12, 22, '5.0', '11.0', '51.0'),
(49, 13, 5, '17.0', '23.0', '50.0'),
(50, 13, 12, '22.0', '11.0', '33.0'),
(51, 13, 13, '22.0', '20.0', '44.0'),
(52, 13, 19, '4.0', '8.0', '48.0'),
(53, 13, 31, '20.0', '28.0', '55.0'),
(54, 13, 50, '12.0', '23.0', '45.0'),
(55, 13, 53, '0.0', '0.0', '0.0'),
(56, 13, 54, '0.0', '0.0', '0.0'),
(57, 13, 15, '11.0', '22.0', '33.0'),
(58, 13, 18, '10.0', '20.0', '40.0'),
(59, 13, 32, '6.0', '22.0', '34.0'),
(60, 13, 51, '21.0', '22.0', '42.0'),
(61, 14, 3, '0.0', '0.0', '0.0'),
(62, 14, 11, '0.0', '0.0', '0.0'),
(63, 15, 5, '10.0', '18.0', '55.0'),
(64, 15, 12, '14.0', '17.0', '48.0'),
(65, 15, 13, '12.0', '15.0', '33.0'),
(66, 19, 50, '23.0', '19.0', '55.0'),
(67, 19, 51, '11.0', '17.0', '44.0'),
(68, 23, 1, '0.0', '0.0', '0.0'),
(69, 23, 9, '0.0', '0.0', '0.0'),
(70, 23, 10, '0.0', '0.0', '0.0'),
(71, 23, 14, '0.0', '0.0', '0.0');

-- --------------------------------------------------------

--
-- Stand-in structure for view `exam_subjectviews`
--
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
-- --------------------------------------------------------

--
-- Table structure for table `exams`
--

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=24 ;

--
-- Dumping data for table `exams`
--

INSERT INTO `exams` (`exam_id`, `exam_desc`, `class_id`, `subject_classlevel_id`, `weightageCA1`, `weightageCA2`, `weightageExam`, `employee_id`, `exammarked_status_id`, `setup_date`) VALUES
(2, 'Exm Studey', NULL, 2, 22, 28, 50, 2, 2, '2014-09-04 03:10:02'),
(3, 'yes og', NULL, 9, 15, 25, 60, 2, 2, '2014-09-04 03:11:02'),
(4, 'gens eng', NULL, 15, 33, 11, 56, 2, 1, '2014-09-10 10:07:07'),
(5, 'English Gens', NULL, 16, 20, 20, 60, 2, 1, '2014-09-10 10:08:07'),
(6, 'Writing Exercise', NULL, 17, 30, 30, 60, 2, 1, '2014-09-15 04:22:25'),
(7, 'General Mathematics Exam', NULL, 18, 25, 25, 60, 2, 1, '2014-09-19 09:50:14'),
(8, ' Phisical Education Exam', NULL, 19, 25, 25, 70, 2, 1, '2014-09-23 09:13:57'),
(9, '2nd term English Gens', NULL, 20, 20, 20, 60, 2, 1, '2014-09-10 10:08:07'),
(10, '2nd term Writing Exercise', NULL, 21, 30, 30, 60, 2, 1, '2014-09-15 04:22:25'),
(11, '2nd term General Mathematics Exam', NULL, 22, 30, 30, 60, 2, 1, '2014-09-19 09:50:14'),
(12, '2nd term Phisical Education Exam', NULL, 23, 30, 25, 65, 2, 1, '2014-09-23 09:13:57'),
(13, ' For Mathematics', NULL, 24, 30, 30, 60, 2, 1, '2014-09-23 04:31:41'),
(14, 'Exam for French', NULL, 11, 20, 20, 50, 2, 2, '2014-10-13 02:52:43'),
(15, 'Drawing Exams ', 36, 13, 20, 20, 60, 2, 1, '2014-10-15 03:09:19'),
(16, 'I.R.S Studies', 38, 9, 25, 25, 60, 2, 2, '2014-10-15 04:04:36'),
(17, 'I. R. S.', 36, 9, 30, 30, 60, 2, 2, '2014-10-15 04:10:04'),
(18, 'Maths Exam', 39, 24, 25, 25, 60, 2, 2, '2014-10-15 05:58:51'),
(19, 'C. S.', 39, 36, 25, 20, 65, 2, 1, '2014-10-15 06:41:30'),
(20, 'Igbo Lang.', 11, 12, 20, 20, 60, 4, 2, '2014-10-16 11:03:20'),
(21, 'English Primary', 36, 24, 25, 25, 50, 4, 2, '2014-10-23 09:01:30'),
(22, 'Intro Tech Exams', 8, 10, 30, 30, 60, 2, 2, '2014-10-23 09:27:56'),
(23, 'Intro Tech Exam', 8, 37, 20, 20, 60, 4, 2, '2014-10-23 09:32:09');

-- --------------------------------------------------------

--
-- Stand-in structure for view `examsdetails_reportviews`
--
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
-- --------------------------------------------------------

--
-- Table structure for table `grades`
--

CREATE TABLE IF NOT EXISTS `grades` (
`grades_id` int(11) NOT NULL,
  `grade` varchar(20) DEFAULT NULL,
  `grade_abbr` varchar(3) DEFAULT NULL,
  `classgroup_id` int(11) DEFAULT NULL,
  `lower_bound` decimal(4,1) DEFAULT NULL,
  `upper_bound` decimal(4,1) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=21 ;

--
-- Dumping data for table `grades`
--

INSERT INTO `grades` (`grades_id`, `grade`, `grade_abbr`, `classgroup_id`, `lower_bound`, `upper_bound`) VALUES
(1, 'Pass', 'P', 1, '50.0', '100.0'),
(2, 'Fail', 'F', 1, '0.0', '49.9'),
(3, 'Pass', 'P', 2, '50.0', '100.0'),
(4, 'Fail', 'F', 2, '0.0', '49.9'),
(5, 'Excellent', 'A', 3, '70.0', '100.0'),
(6, 'Credit', 'C', 3, '50.0', '69.9'),
(7, 'Pass', 'P', 3, '40.0', '49.9'),
(8, 'Fail', 'F', 3, '0.0', '39.9'),
(9, 'Excellent', 'A', 4, '70.0', '100.0'),
(10, 'Credit', 'C', 4, '50.0', '69.9'),
(11, 'Pass', 'P', 4, '40.0', '49.9'),
(12, 'Fail', 'F', 4, '0.0', '39.9'),
(13, 'Excellent', 'A', 5, '70.0', '100.0'),
(14, 'Credit', 'C', 5, '50.0', '69.9'),
(15, 'Pass', 'P', 5, '40.0', '49.9'),
(16, 'Fail', 'F', 5, '0.0', '39.9'),
(17, 'Excellent', 'A', 6, '70.0', '100.0'),
(18, 'Credit', 'C', 6, '50.0', '69.9'),
(19, 'Pass', 'P', 6, '40.0', '49.9'),
(20, 'Fail', 'F', 6, '0.0', '39.9');

-- --------------------------------------------------------

--
-- Table structure for table `item_bills`
--

CREATE TABLE IF NOT EXISTS `item_bills` (
`item_bill_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `price` decimal(12,2) NOT NULL,
  `classlevel_id` int(11) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=16 ;

--
-- Dumping data for table `item_bills`
--

INSERT INTO `item_bills` (`item_bill_id`, `item_id`, `price`, `classlevel_id`) VALUES
(1, 1, '15000.00', 2),
(2, 3, '2500.00', 2),
(3, 5, '3500.00', 2),
(4, 6, '2300.00', 2),
(5, 1, '18000.00', 6),
(6, 3, '2500.00', 6),
(7, 5, '4000.00', 6),
(8, 6, '3000.00', 6),
(9, 4, '2000.00', 6),
(10, 2, '3450.00', 2),
(11, 2, '5000.00', 6),
(12, 1, '16700.00', 4),
(13, 5, '5600.00', 4),
(14, 1, '25000.00', 16),
(15, 6, '2600.00', 16);

-- --------------------------------------------------------

--
-- Table structure for table `item_types`
--

CREATE TABLE IF NOT EXISTS `item_types` (
`item_type_id` int(11) NOT NULL,
  `item_type` varchar(50) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=4 ;

--
-- Dumping data for table `item_types`
--

INSERT INTO `item_types` (`item_type_id`, `item_type`) VALUES
(1, 'Universal'),
(2, 'Variable'),
(3, 'Electives');

-- --------------------------------------------------------

--
-- Table structure for table `item_variables`
--

CREATE TABLE IF NOT EXISTS `item_variables` (
`item_variable_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `student_id` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `academic_term_id` int(11) NOT NULL,
  `price` decimal(10,2) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=6 ;

--
-- Dumping data for table `item_variables`
--

INSERT INTO `item_variables` (`item_variable_id`, `item_id`, `student_id`, `class_id`, `academic_term_id`, `price`) VALUES
(1, 4, 5, 9, 4, '4500.00'),
(2, 7, 5, 36, 4, '5500.00'),
(3, 2, 5, NULL, 4, '6700.00'),
(4, 6, NULL, 36, 4, '3200.00'),
(5, 5, 5, NULL, 4, '3300.00');

-- --------------------------------------------------------

--
-- Table structure for table `items`
--

CREATE TABLE IF NOT EXISTS `items` (
`item_id` int(11) NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `item_status_id` int(3) NOT NULL DEFAULT '2',
  `item_description` text NOT NULL,
  `item_type_id` int(11) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=8 ;

--
-- Dumping data for table `items`
--

INSERT INTO `items` (`item_id`, `item_name`, `item_status_id`, `item_description`, `item_type_id`) VALUES
(1, 'Tuition Fees', 1, 'Tuition Fees is Paid on a Terminal basis', 1),
(2, 'Lesson Fee', 2, 'Lesson Fee is Paid on a Terminal basis', 2),
(3, 'Uniform ', 1, 'Uniform Being paid annually', 2),
(4, 'Sport Wear ', 1, 'Sport Wear Being paid annually ', 2),
(5, 'Text Books', 1, 'Text Books Being paid annually', 2),
(6, 'Note Books', 1, 'Note Books Being paid annually', 3),
(7, 'Summer School', 1, 'Summer School Being paid annually', 3);

-- --------------------------------------------------------

--
-- Table structure for table `local_govts`
--

CREATE TABLE IF NOT EXISTS `local_govts` (
`local_govt_id` int(3) unsigned NOT NULL,
  `local_govt_name` varchar(50) DEFAULT NULL,
  `state_id` int(3) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=781 ;

--
-- Dumping data for table `local_govts`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `master_setups`
--

CREATE TABLE IF NOT EXISTS `master_setups` (
`master_setup_id` int(11) NOT NULL,
  `setup` varchar(30) NOT NULL DEFAULT 'smartedu',
  `master_record_id` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=2 ;

--
-- Dumping data for table `master_setups`
--

INSERT INTO `master_setups` (`master_setup_id`, `setup`, `master_record_id`) VALUES
(1, 'smartedu', 8);

-- --------------------------------------------------------

--
-- Table structure for table `message_recipients`
--

CREATE TABLE IF NOT EXISTS `message_recipients` (
`message_recipient_id` int(11) NOT NULL,
  `recipient_name` varchar(150) NOT NULL,
  `mobile_number` varchar(15) NOT NULL,
  `email` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=8 ;

--
-- Dumping data for table `message_recipients`
--

INSERT INTO `message_recipients` (`message_recipient_id`, `recipient_name`, `mobile_number`, `email`, `created_at`) VALUES
(1, 'Isiaka Mohammad', '0900330029', 'shaku@ymail.com', '2015-01-14 11:58:21'),
(2, 'Inuwa Yunusa Adams', '07023649260', 'yunus@gmail.com', '2015-01-14 12:11:49'),
(3, 'Uchenna George', '08030734377', 'kingsley4united@yahoo.com', '2015-01-14 12:12:29'),
(4, 'Ijokun Duke ', '08033884490', '', '2015-01-14 12:31:12'),
(5, 'Uche Chinaks', '08139516789', 'chinakzz@gmail.com', '2015-01-14 13:09:21'),
(6, 'Emma Shaibu', '08073433803', 'emmagd4@gmail.com', '2015-01-14 13:32:14'),
(7, 'Maazi', '08061539278', 'nondefyde@gmail.com', '2015-02-05 08:53:09');

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE IF NOT EXISTS `messages` (
`message_id` int(11) NOT NULL,
  `message` text NOT NULL,
  `message_subject` varchar(20) NOT NULL,
  `sms_count` int(11) NOT NULL,
  `email_count` int(11) NOT NULL,
  `message_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `message_sender` int(11) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=17 ;

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`message_id`, `message`, `message_subject`, `sms_count`, `email_count`, `message_date`, `message_sender`) VALUES
(1, 'Yeah Testing SMS and Emailing', '', 2, 2, '2015-01-14 10:52:51', 2),
(2, 'Checking SMS and Email', '', 1, 1, '2015-01-14 13:23:00', 2),
(3, 'If You Receive this meaning SMS and Email services are currently functional for SmartSchool Management System.\r\nZuma Softwares Limited.', 'SMS Check', 2, 2, '2015-01-14 13:40:37', 2),
(4, 'If You Receive this meaning SMS and Email services are currently functional for SmartSchool Management System.\r\nZuma Softwares Limited.', 'Seasons Gre', 1, 1, '2015-01-14 13:43:20', 2),
(5, 'If You Receive this meaning SMS and Email services are currently functional for SmartSchool Management System.\r\nZuma Softwares Limited.', 'SMS Check', 2, 2, '2015-01-14 13:46:29', 2),
(6, 'Acct: ******9806\r\nAmt: NGN19,042\r\nDesc: POS, www.myapptemplates.com +18005194199 PL- 1 USD STAN9999021596\r\nDoc No: 9999021596\r\nAvail Bal: NGN2,540.60', 'GTBank', 1, 0, '2015-02-05 09:05:25', 2),
(7, 'Acct: ******9806\r\nAmt: NGN19,042\r\nDesc: POS, www.myapptemplates.com +18005194199 PL- 1 USD STAN9999021596\r\nDoc No: 9999021596\r\nAvail Bal: NGN2,540.60', 'GTBank', 1, 0, '2015-02-05 09:08:37', 2),
(8, 'if(substr($mobile_no, 0, 1) === ''0''){\r\n            $no = ''234'' . substr ($mobile_no, 1);\r\n        }elseif (substr($mobile_no, 0, 3) === ''234'') {\r\n        	$no = $m', 'GTBank', 1, 0, '2015-02-05 09:26:04', 2),
(9, 'if(substr($mobile_no, 0, 1) === ''0''){\r\n            $no = ''234'' . substr ($mobile_no, 1);\r\n        }elseif (substr($mobile_no, 0, 3) === ''234'') {\r\n        	$no = $m', 'GTBank', 1, 1, '2015-02-05 09:26:36', 2),
(14, 'Testing', 'SMS Check', 2, 2, '2015-02-05 12:28:27', 2),
(15, 'TESTING', 'Seasons Gre', 3, 3, '2015-02-05 12:30:07', 2),
(16, 'jsjsj', 'Testing', 0, 1, '2015-02-05 12:36:18', 2);

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE IF NOT EXISTS `order_items` (
`order_item_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `price` decimal(12,2) NOT NULL,
  `quantity` int(3) NOT NULL DEFAULT '1',
  `item_id` int(11) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=83 ;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`order_item_id`, `order_id`, `price`, `quantity`, `item_id`) VALUES
(1, 1, '15000.00', 1, 1),
(2, 1, '2500.00', 1, 3),
(3, 1, '3500.00', 1, 5),
(4, 3, '18000.00', 1, 1),
(5, 3, '2500.00', 1, 3),
(6, 3, '4000.00', 1, 5),
(7, 3, '2000.00', 1, 4),
(8, 4, '25000.00', 1, 1),
(9, 5, '15000.00', 1, 1),
(10, 5, '2500.00', 1, 3),
(11, 5, '3500.00', 1, 5),
(12, 6, '15000.00', 1, 1),
(13, 6, '2500.00', 1, 3),
(14, 6, '3500.00', 1, 5),
(15, 7, '15000.00', 1, 1),
(16, 7, '2500.00', 1, 3),
(17, 7, '3500.00', 1, 5),
(18, 8, '18000.00', 1, 1),
(19, 8, '2500.00', 1, 3),
(20, 8, '4000.00', 1, 5),
(21, 8, '2000.00', 1, 4),
(22, 9, '18000.00', 1, 1),
(23, 9, '2500.00', 1, 3),
(24, 9, '4000.00', 1, 5),
(25, 9, '2000.00', 1, 4),
(26, 10, '15000.00', 1, 1),
(27, 10, '2500.00', 1, 3),
(28, 10, '3500.00', 1, 5),
(29, 11, '18000.00', 1, 1),
(30, 11, '2500.00', 1, 3),
(31, 11, '4000.00', 1, 5),
(32, 11, '2000.00', 1, 4),
(33, 14, '18000.00', 1, 1),
(34, 14, '2500.00', 1, 3),
(35, 14, '4000.00', 1, 5),
(36, 14, '2000.00', 1, 4),
(37, 15, '18000.00', 1, 1),
(38, 15, '2500.00', 1, 3),
(39, 15, '4000.00', 1, 5),
(40, 15, '2000.00', 1, 4),
(41, 18, '15000.00', 1, 1),
(42, 18, '2500.00', 1, 3),
(43, 18, '3500.00', 1, 5),
(44, 20, '25000.00', 1, 1),
(45, 21, '25000.00', 1, 1),
(46, 25, '25000.00', 1, 1),
(47, 26, '18000.00', 1, 1),
(48, 26, '2500.00', 1, 3),
(49, 26, '4000.00', 1, 5),
(50, 26, '2000.00', 1, 4),
(51, 27, '18000.00', 1, 1),
(52, 27, '2500.00', 1, 3),
(53, 27, '4000.00', 1, 5),
(54, 27, '2000.00', 1, 4),
(55, 35, '25000.00', 1, 1),
(56, 37, '25000.00', 1, 1),
(57, 43, '25000.00', 1, 1),
(58, 44, '18000.00', 1, 1),
(59, 44, '2500.00', 1, 3),
(60, 44, '4000.00', 1, 5),
(61, 44, '2000.00', 1, 4),
(62, 45, '18000.00', 1, 1),
(63, 45, '2500.00', 1, 3),
(64, 45, '4000.00', 1, 5),
(65, 45, '2000.00', 1, 4),
(66, 47, '18000.00', 1, 1),
(67, 47, '2500.00', 1, 3),
(68, 47, '4000.00', 1, 5),
(69, 47, '2000.00', 1, 4),
(70, 48, '18000.00', 1, 1),
(71, 48, '2500.00', 1, 3),
(72, 48, '4000.00', 1, 5),
(73, 48, '2000.00', 1, 4),
(74, 50, '25000.00', 1, 1),
(75, 51, '18000.00', 1, 1),
(76, 51, '2500.00', 1, 3),
(77, 51, '4000.00', 1, 5),
(78, 51, '2000.00', 1, 4),
(79, 52, '15000.00', 1, 1),
(80, 52, '2500.00', 1, 3),
(81, 52, '3500.00', 1, 5),
(82, 53, '25000.00', 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE IF NOT EXISTS `orders` (
`order_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `sponsor_id` int(11) NOT NULL,
  `academic_term_id` int(11) NOT NULL,
  `process_item_id` int(11) DEFAULT NULL,
  `status_id` int(3) NOT NULL DEFAULT '2'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=54 ;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`order_id`, `student_id`, `sponsor_id`, `academic_term_id`, `process_item_id`, `status_id`) VALUES
(1, 1, 2, 4, 1, 1),
(2, 4, 6, 4, 1, 2),
(3, 5, 1, 4, 1, 1),
(4, 6, 1, 4, 1, 2),
(5, 9, 4, 4, 1, 2),
(6, 10, 6, 4, 1, 1),
(7, 11, 5, 4, 1, 2),
(8, 12, 3, 4, 1, 2),
(9, 13, 4, 4, 1, 2),
(10, 14, 29, 4, 1, 2),
(11, 15, 7, 4, 1, 1),
(12, 16, 9, 4, 1, 2),
(13, 17, 8, 4, 1, 2),
(14, 18, 8, 4, 1, 2),
(15, 19, 8, 4, 1, 2),
(16, 20, 10, 4, 1, 2),
(17, 21, 11, 4, 1, 2),
(18, 22, 11, 4, 1, 2),
(19, 24, 13, 4, 1, 2),
(20, 25, 14, 4, 1, 2),
(21, 26, 14, 4, 1, 1),
(22, 27, 11, 4, 1, 2),
(23, 28, 6, 4, 1, 2),
(24, 29, 16, 4, 1, 2),
(25, 30, 12, 4, 1, 2),
(26, 31, 16, 4, 1, 2),
(27, 32, 17, 4, 1, 2),
(28, 33, 12, 4, 1, 2),
(29, 34, 17, 4, 1, 2),
(30, 35, 6, 4, 1, 2),
(31, 36, 18, 4, 1, 2),
(32, 37, 18, 4, 1, 2),
(33, 38, 8, 4, 1, 2),
(34, 39, 20, 4, 1, 2),
(35, 40, 20, 4, 1, 2),
(36, 42, 12, 4, 1, 2),
(37, 43, 12, 4, 1, 2),
(38, 44, 12, 4, 1, 2),
(39, 45, 6, 4, 1, 2),
(40, 46, 12, 4, 1, 2),
(41, 47, 22, 4, 1, 2),
(42, 48, 23, 4, 1, 2),
(43, 49, 24, 4, 1, 2),
(44, 50, 25, 4, 1, 2),
(45, 51, 25, 4, 1, 2),
(46, 52, 26, 4, 1, 2),
(47, 53, 27, 4, 1, 2),
(48, 54, 16, 4, 1, 2),
(49, 55, 24, 4, 1, 2),
(50, 59, 1, 4, 1, 2),
(51, 60, 16, 4, 1, 2),
(52, 61, 13, 4, 1, 2),
(53, 62, 3, 4, 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `process_items`
--

CREATE TABLE IF NOT EXISTS `process_items` (
`process_item_id` int(11) NOT NULL,
  `process_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `process_by` int(11) NOT NULL,
  `academic_term_id` int(11) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=2 ;

--
-- Dumping data for table `process_items`
--

INSERT INTO `process_items` (`process_item_id`, `process_date`, `process_by`, `academic_term_id`) VALUES
(1, '2015-01-15 11:00:00', 2, 4);

-- --------------------------------------------------------

--
-- Table structure for table `relationship_types`
--

CREATE TABLE IF NOT EXISTS `relationship_types` (
`relationship_type_id` int(3) unsigned NOT NULL,
  `relationship_type` varchar(50) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=10 ;

--
-- Dumping data for table `relationship_types`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `salutations`
--

CREATE TABLE IF NOT EXISTS `salutations` (
`salutation_id` int(3) unsigned NOT NULL,
  `salutation_abbr` varchar(10) DEFAULT NULL,
  `salutation_name` varchar(50) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=12 ;

--
-- Dumping data for table `salutations`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `setups`
--

CREATE TABLE IF NOT EXISTS `setups` (
`setup_id` int(11) NOT NULL,
  `school_name` text NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `email` varchar(50) NOT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `subdomain` varchar(150) NOT NULL,
  `progress` int(3) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `skill_assessments`
--

CREATE TABLE IF NOT EXISTS `skill_assessments` (
`skill_assessment_id` int(11) NOT NULL,
  `skill_id` int(11) NOT NULL,
  `assessment_id` int(11) NOT NULL,
  `option` int(11) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=52 ;

--
-- Dumping data for table `skill_assessments`
--

INSERT INTO `skill_assessments` (`skill_assessment_id`, `skill_id`, `assessment_id`, `option`) VALUES
(1, 8, 1, 3),
(2, 16, 1, 5),
(3, 12, 1, 5),
(4, 6, 1, 4),
(5, 2, 1, 4),
(6, 1, 1, 4),
(7, 11, 1, 3),
(8, 4, 1, 3),
(9, 9, 1, 2),
(10, 15, 1, 3),
(11, 10, 1, 4),
(12, 17, 1, 3),
(13, 7, 1, 4),
(14, 13, 1, 5),
(15, 3, 1, 4),
(16, 5, 1, 4),
(17, 14, 1, 5),
(18, 8, 2, 2),
(19, 16, 2, 3),
(20, 12, 2, 4),
(21, 6, 2, 5),
(22, 2, 2, 4),
(23, 1, 2, 3),
(24, 11, 2, 2),
(25, 4, 2, 3),
(26, 9, 2, 4),
(27, 15, 2, 5),
(28, 10, 2, 4),
(29, 17, 2, 3),
(30, 7, 2, 2),
(31, 13, 2, 3),
(32, 3, 2, 4),
(33, 5, 2, 5),
(34, 14, 2, 4),
(35, 8, 3, 1),
(36, 16, 3, 1),
(37, 12, 3, 1),
(38, 6, 3, 1),
(39, 2, 3, 2),
(40, 1, 3, 2),
(41, 11, 3, 2),
(42, 4, 3, 2),
(43, 9, 3, 3),
(44, 15, 3, 3),
(45, 10, 3, 3),
(46, 17, 3, 3),
(47, 7, 3, 3),
(48, 13, 3, 4),
(49, 3, 3, 4),
(50, 5, 3, 4),
(51, 14, 3, 4);

-- --------------------------------------------------------

--
-- Table structure for table `skills`
--

CREATE TABLE IF NOT EXISTS `skills` (
`skill_id` int(11) NOT NULL,
  `skill` varchar(200) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=18 ;

--
-- Dumping data for table `skills`
--

INSERT INTO `skills` (`skill_id`, `skill`) VALUES
(1, 'Handwriting'),
(2, 'Fluency'),
(3, 'Sports'),
(4, 'Horse riding'),
(5, 'Swimming'),
(6, 'Craft'),
(7, 'Punctuality'),
(8, 'Attendance'),
(9, 'Neatness'),
(10, 'Politeness'),
(11, 'Honesty'),
(12, 'Cooperation'),
(13, 'Self control'),
(14, 'Use of Initiative'),
(15, 'Perseverance'),
(16, 'Attentiveness in Class'),
(17, 'Promptness in Completing Assignment');

-- --------------------------------------------------------

--
-- Table structure for table `sponsors`
--

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
  `image_url` varchar(100) DEFAULT NULL,
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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=34 ;

--
-- Dumping data for table `sponsors`
--

INSERT INTO `sponsors` (`sponsor_id`, `sponsor_no`, `first_name`, `other_name`, `salutation_id`, `occupation`, `company_name`, `company_address`, `email`, `image_url`, `contact_address`, `local_govt_id`, `state_id`, `country_id`, `mobile_number1`, `mobile_number2`, `created_by`, `sponsorship_type_id`, `created_at`, `updated_at`) VALUES
(1, 'spn0001', 'KayOh', 'China', 9, ' Software Developer', 'Softsmart Business Solutions', '25 Durban Street, Off Ademola Adetokumbo Creasent, Wuse II, Abuja', 'kheengz@gmail.com', 'sponsors/1.jpg', 'CBN Quarters Wuse II FCT Abuja, Nigeria', 212, 37, 140, '08030734377', '08022020075', 1, 1, '2015-03-11 06:18:18', '2015-03-12 08:45:24'),
(2, 'spn0002', 'Maazi', 'Okarfor', 4, 'Freelancer Programmer', 'Joker''s Club', 'Ikuna, Ilewe Ikotun', 'nondefyde@yahoo.com', NULL, '', 7, 1, 140, '080294834889', '090383662892', 1, 3, '2014-06-14 05:46:46', '2014-07-03 11:59:37'),
(3, 'spn0003', 'Usman', 'Abrahim Mohammed', 11, 'Farmer', '', '', 'usman@yahoo.com', NULL, '', NULL, 0, 134, '07034555544', '07032345267', 1, 2, '2014-06-14 05:53:01', '2014-07-03 11:59:37'),
(4, 'spn0004', 'Emmanuel', 'Skele Jigawa', 9, 'Programmer', '', 'Dogon Bauchi Road S/G Zaria', 'emma@gmail.com', NULL, 'No 22 Jigawa Road S/G Lagos', NULL, 0, 137, '039474625278', '', 1, 1, '2014-06-14 06:02:44', '2014-07-03 11:59:37'),
(5, 'spn0005', 'Dickson', 'Emmanuel Akpan', 9, 'Programmer', 'Agent Dickson Consultance', '', 'dickson@hotmail.co.za', NULL, 'CBN Quarters Wuse II FCT Abuja', 5, 1, 140, '04950585080', '07032345267', 9, 1, '2014-06-17 10:21:25', '2014-07-03 11:59:37'),
(6, 'spn0006', 'Ibrahim', 'Audu', 6, 'Business', '', '', 'audu@gmail.com', NULL, 'No 21 Lagos street S/G', 178, 8, 140, '0930738865', '092985479', 1, 1, '2014-06-27 04:15:34', '2014-07-03 11:59:37'),
(7, 'spn0007', 'Dorathy', 'Akume', 7, 'Legal Practinioner', 'Nigeria Bar Association', 'Victoria Island Lagos', 'akume@roketmail.com', NULL, 'Aminu Road S/G Munchiya, Kaduna', 114, 32, 140, '0930738865', '', 1, 1, '2014-07-03 01:45:19', '2014-07-03 12:45:20'),
(8, 'spn0008', 'Abdullahi Mariam', 'Ojochide', 3, 'Accountant', 'Guarantee Trust Bank', '124C Ayilara Street, Ojuelegba road', 'chidepink@gmail.com', NULL, 'No, 35 Adewuyi streeet, Ijeshastedo Surulere Lagos', 470, 16, 140, '07037830508', '08083580024', 6, 3, '2014-07-22 03:38:23', '2014-07-22 14:38:23'),
(9, 'spn0009', 'Eric Kelvin', 'Desmond', 5, 'Doctor', 'RedRose Clinic', '4A, Aja Town', 'desmond@yahoo.com', NULL, 'No, 14 Festac Town', 181, 8, 140, '08029554329', '08023310427', 6, 2, '2014-07-22 03:44:30', '2014-07-22 14:44:30'),
(10, 'spn0010', 'Nuhu', 'Inuwa Desmond', 11, 'Accountant', 'First Bank', '5b Mile2 road', 'luvnuhu@yahoo.com', NULL, '3, Festac Town', 339, 13, 140, '07033560739', '08024262994', 6, 1, '2014-07-22 04:21:30', '2014-07-22 15:21:30'),
(11, 'spn0011', 'Haruna', 'Ibrahim', 5, 'Architecture', 'Freelancer', '', 'ibrahim.haruna@yahoo.com', NULL, 'No 77 Itire Road Surulere, Lagos', 147, 7, 140, '08035268493', '09047568475', 6, 1, '2014-09-10 01:16:52', '2014-09-10 12:16:53'),
(12, 'spn0012', 'ABUBAKAR', 'YUSUF', 11, 'LAWYER', '', '', 'ABUBAKARYUSUF@YAHOO.COM', NULL, '111 IJESHA ROAD LAGOS', 340, 13, 140, '08081593158', '07060627828', 6, 1, '2014-09-10 01:44:32', '2014-09-10 12:54:24'),
(13, 'spn0013', 'Adamu ', 'Jamiu', 11, 'Doctor', 'Ovansa Hospital and Maternity', '3, Oremeji street', 'adamuja@yahoo.com', NULL, '3, Shodimu street', 137, 6, 140, '09066778855', '08033442211', 6, 1, '2014-09-10 01:58:01', '2014-09-10 12:58:01'),
(14, 'spn0014', 'Ben', 'Affleck', 8, 'Engineer', 'Benson&co', '909, Iju Lagos', 'benafleck@gmail.com', NULL, '5, washway Town', 477, 16, 140, '08122224455', '09077665544', 6, 2, '2014-09-10 02:15:40', '2014-09-10 13:15:40'),
(15, 'spn0015', 'Casey', 'Affleck', 7, 'Barrister', 'God''s gift', '3, Fapounda street', 'afflecttings@gmail.com', NULL, '3, Falolu street', 203, 9, 140, '08099776655', '08155667788', 6, 3, '2014-09-10 03:19:39', '2014-09-10 14:19:40'),
(16, 'spn0016', 'Johnny', 'Depp', 5, 'Doctor', 'Living Spring Hospital', '1, Ojuelegba street', 'johnde@gmail.com', NULL, '4, olorunda street', 220, 37, 140, '09055667788', '09055443322', 6, 1, '2014-09-10 03:30:55', '2014-09-10 14:30:55'),
(17, 'spn0017', 'Abdullahi', 'Oseni', 6, 'Accountant', 'Zuma Communications Limited', '124c Ayilara Street', 'abdul@yahoo.com', NULL, '35, Fectac Town', 176, 8, 140, '09024556634', '08029554324', 6, 1, '2014-09-10 03:42:06', '2014-09-10 14:42:06'),
(18, 'spn0018', 'Mohammed', 'Nuhu', 4, 'Accountant', 'First Bank', 'Victoria Island City', 'nuhluvchide@gmail.com', NULL, '24, Adewuyi street', 339, 13, 140, '08024262994', '07033560739', 6, 2, '2014-09-10 03:56:35', '2014-09-10 14:56:35'),
(19, 'spn0019', 'MOHAMMED', 'INUWA', 9, 'LAWYER', '', '', 'MCKUMDO@YAHOO.COM', NULL, '24 ADEWUYI STREET OF IJESHA ', NULL, 13, 140, '08081593158', '08080204017', 6, 1, '2014-09-10 04:02:39', '2014-09-10 15:02:40'),
(20, 'spn0020', 'Hassan', 'Oseni', 1, 'Accountant', 'Guarantee Trust Bank', '123, Agbebi raod', 'osehass@gmail.com', NULL, '97, Ijesha road', 343, 15, 140, '09077665544', '08055443322', 6, 2, '2014-09-11 10:08:49', '2014-09-11 09:08:50'),
(21, 'spn0021', 'Oseni ', 'Gift', 3, 'Student', '', '', 'osengift@yahoo.com', NULL, '39, Festac Town', 272, 31, 140, '07033560738', '07037830509', 6, 3, '2014-09-11 10:36:51', '2014-09-11 09:36:51'),
(22, 'spn0022', 'Emmanuel', 'Shuaibu', 1, 'Accountant', 'First Bank', '', 'emm@gmail.com', NULL, '89 okunola street', 267, 11, 140, '09066778855', '08155667788', 6, 1, '2014-09-11 12:21:33', '2014-09-11 11:21:34'),
(23, 'spn0023', 'Emmanuel', 'Sylvester', 10, 'Doctor', '', '', 'sylvester@yahoo.com', NULL, '45, Adae street', 274, 31, 140, '09033445566', '09011223344', 6, 1, '2014-09-11 12:37:49', '2014-09-11 11:37:49'),
(24, 'spn0024', 'MOHAMMED', 'ISSAH', 5, 'CUSTOM', '', '', 'MOHAMMEDISSAH@GMAIL.COM', NULL, '1 ILE OGBO STREET OFF IJESHA LAGOS', NULL, 13, 140, '08024387677', '08024387677', 6, 1, '2014-09-11 01:03:32', '2014-09-11 12:03:32'),
(25, 'spn0025', 'Peter', 'Peterson', 4, 'Business ', '', '', 'peter@gmail.com', NULL, '456, Adedeji street', 181, 8, 140, '08122223355', '07088996655', 6, 1, '2014-09-11 01:14:12', '2014-09-11 12:14:12'),
(26, 'spn0026', 'Joshua', 'Johnson', 10, 'Barrister', '', '', 'johns@yahoo.com', NULL, '3,Tapa Street', 286, 33, 140, '07033560738', '', 6, 1, '2014-09-11 01:32:09', '2014-09-11 12:32:09'),
(27, 'spn0027', 'Ebube', 'Chima', 8, 'Accountant', '', '', 'ebu@yahoo.com', NULL, '3, Adeniran Ogunsanya way', 316, 13, 140, '08024262994', '', 6, 1, '2014-09-11 01:41:38', '2014-09-11 12:41:38'),
(28, 'spn0028', 'Vivian', 'George', 8, 'Banker', NULL, 'GTBank Owerri', 'vivian@gmail.com', NULL, 'World Banking Estate Owerri', 290, 12, 140, '08030734377', '094387324', 2, NULL, '2014-10-24 11:17:22', '2014-10-24 10:17:22'),
(29, 'spn0029', 'Ibrahim ', 'Bala', 6, 'Trader', NULL, '', '', NULL, 'Line Zumo', 277, 33, 140, '08030734377', '', 2, NULL, '2014-10-26 12:53:05', '2014-12-22 11:42:39'),
(30, 'spn0030', 'Ebube', 'Chidi', 7, 'Business', NULL, '', 'vivian@gmail.com', NULL, 'Samaru', 288, 12, 140, '08024262994', '', 2, NULL, '2014-10-26 12:59:27', '2014-10-26 11:59:27'),
(32, 'spn0032', 'Peter', 'Malgwi', 8, 'Lecturer', NULL, 'Kebbi State University', 'peter@gmail.com', NULL, 'Katsina Ala', 142, 7, 140, '08135201037', '', 2, NULL, '2014-10-26 01:11:21', '2014-10-26 12:11:21'),
(33, 'spn0033', 'Obinna', 'Ekwueme', 8, NULL, NULL, NULL, 'kingsley4united@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08030734377', NULL, 2, NULL, '2015-03-10 03:07:43', '2015-03-10 14:07:44');

-- --------------------------------------------------------

--
-- Table structure for table `sponsorship_types`
--

CREATE TABLE IF NOT EXISTS `sponsorship_types` (
`sponsorship_type_id` int(3) unsigned NOT NULL,
  `sponsorship_type` varchar(50) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=4 ;

--
-- Dumping data for table `sponsorship_types`
--

INSERT INTO `sponsorship_types` (`sponsorship_type_id`, `sponsorship_type`) VALUES
(1, 'Private'),
(2, 'Corporate'),
(3, 'Scholarship');

-- --------------------------------------------------------

--
-- Table structure for table `spouse_details`
--

CREATE TABLE IF NOT EXISTS `spouse_details` (
`spouse_detail_id` int(11) NOT NULL,
  `employee_id` int(5) NOT NULL,
  `spouse_name` varchar(100) NOT NULL,
  `spouse_number` varchar(15) NOT NULL,
  `spouse_employer` varchar(150) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=3 ;

--
-- Dumping data for table `spouse_details`
--

INSERT INTO `spouse_details` (`spouse_detail_id`, `employee_id`, `spouse_name`, `spouse_number`, `spouse_employer`) VALUES
(1, 16, 'Mr. John Audu', '07188992233', 'First Bank P.L.C'),
(2, 19, 'Mrs. Mariam Audu', '09083746193', 'Marketer');

-- --------------------------------------------------------

--
-- Table structure for table `states`
--

CREATE TABLE IF NOT EXISTS `states` (
`state_id` int(3) unsigned NOT NULL,
  `state_name` varchar(30) DEFAULT NULL,
  `state_code` varchar(5) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=38 ;

--
-- Dumping data for table `states`
--

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

-- --------------------------------------------------------

--
-- Table structure for table `status`
--

CREATE TABLE IF NOT EXISTS `status` (
`status_id` int(11) NOT NULL,
  `status` varchar(50) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=3 ;

--
-- Dumping data for table `status`
--

INSERT INTO `status` (`status_id`, `status`) VALUES
(1, 'Active'),
(2, 'Inactive');

-- --------------------------------------------------------

--
-- Stand-in structure for view `student_feesqueryviews`
--
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
-- --------------------------------------------------------

--
-- Stand-in structure for view `student_feesviews`
--
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
-- --------------------------------------------------------

--
-- Table structure for table `student_status`
--

CREATE TABLE IF NOT EXISTS `student_status` (
`student_status_id` int(3) unsigned NOT NULL,
  `student_status` varchar(50) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=6 ;

--
-- Dumping data for table `student_status`
--

INSERT INTO `student_status` (`student_status_id`, `student_status`) VALUES
(1, 'Active'),
(2, 'Graduated'),
(3, 'Suspended'),
(4, 'Transfered'),
(5, 'Deceased');

-- --------------------------------------------------------

--
-- Table structure for table `students`
--

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=64 ;

--
-- Dumping data for table `students`
--

INSERT INTO `students` (`student_id`, `sponsor_id`, `first_name`, `surname`, `other_name`, `student_no`, `image_url`, `gender`, `birth_date`, `class_id`, `religion`, `previous_school`, `academic_term_id`, `term_admitted`, `student_status_id`, `local_govt_id`, `state_id`, `country_id`, `relationtype_id`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 2, 'John', 'Adamu', 'Inua', 'stu0001', 'students/1.jpg', 'Female', '2014-05-27', 8, 'Traditional', 'L.E.A school dogon bauchi, Katsina', 4, 'Third Term 2013-2014', 1, 22, 2, 140, 5, 1, '2014-06-13 12:51:15', '2014-10-23 08:47:26'),
(2, 4, 'Samuel', 'Makus', 'Mark', 'stu0002', 'students/2.jpg', 'Male', '2012-12-25', NULL, 'Christainity', 'St. Micheal Anglican High School', 4, 'Third Term 2013-2014', 4, 1, 1, 140, 1, 1, '2014-06-24 11:13:50', '2014-09-12 09:23:56'),
(3, 3, 'Musa', 'Usman', 'Abdulahi', 'stu0003', 'students/3.JPG', 'Male', '2010-06-10', 9, 'Muslim', '', 4, 'Third Term 2013-2014', 3, 330, 13, 140, 3, 1, '2014-06-30 11:56:29', '2015-01-10 19:34:08'),
(4, 6, 'Jamila', 'Audu ', 'Ibrahim', 'stu0004', 'students/4.png', 'Female', '2007-08-15', 15, 'Muslim', '', 4, 'Third Term 2013-2014', 1, 158, 7, 140, 1, 1, '2014-06-30 12:05:17', '2015-03-12 09:45:47'),
(5, 1, 'Kheengz', 'China', 'Odi', 'stu0005', 'students/5.JPG', 'Male', '1988-05-05', 36, 'Christian', 'Depot NA Chindict Barracks Zaria', 4, 'Third Term 2013-2014', 1, 290, 12, 140, 1, 1, '2014-06-30 12:22:47', '2015-01-10 20:33:44'),
(6, 1, 'Emmanuel', 'Dick', 'Dude', 'stu0006', 'students/6.jpg', 'Female', '2014-06-19', 106, 'Traditional', 'Efiong Topko Secondary School', 4, 'Third Term 2013-2014', 1, 178, 8, 140, 6, 1, '2014-06-30 04:33:24', '2014-09-12 09:23:56'),
(7, 2, 'Chinonso', 'Chukwu', 'Maazi', 'stu0007', 'students/7.JPG', 'Female', '2009-05-12', NULL, 'Christian', 'St. Bath Wussasa Zaria', 4, 'Third Term 2013-2014', 1, 80, 4, 140, 2, 1, '2014-07-02 10:29:52', '2014-09-12 09:23:56'),
(8, 1, 'Kingsley', 'Kayoh', 'Kheengz', 'stu0008', 'students/8.JPG', 'Male', '2006-09-07', NULL, 'Christian', 'Depot NA Chindict Barracks Zaria', 4, 'Third Term 2013-2014', 1, 263, 11, 140, 3, 1, '2014-07-02 10:36:17', '2014-09-12 09:23:56'),
(9, 4, 'Esther', 'Emmanuel', 'James', 'stu0009', 'students/9.JPG', 'Female', '2010-06-10', 8, 'Christian', 'Efiong Topko Secondary School', 4, 'Third Term 2013-2014', 1, 771, 10, 140, 3, 1, '2014-07-02 10:39:12', '2014-09-12 09:23:56'),
(10, 6, 'Aisha', 'Ibrahim', 'Ikra', 'stu0010', NULL, 'Female', '2008-08-06', 8, 'Muslim', 'Dogon Bauchi Primary School', 4, 'Third Term 2013-2014', 1, 102, 5, 140, 1, 1, '2014-07-02 10:43:23', '2014-09-12 09:23:56'),
(11, 5, 'Ubong', 'Akpan', 'Jude', 'stu0011', NULL, 'Male', '2012-04-11', 9, 'Traditional', 'Efiong Topko Secondary School', 4, 'Third Term 2013-2014', 1, 178, 8, 140, 3, 1, '2014-07-02 10:47:57', '2014-09-12 09:23:56'),
(12, 3, 'Adamu', 'Usman', 'Sule', 'stu0012', 'students/12.JPG', 'Male', '2002-06-07', 36, 'Muslim', 'Dogon Bauchi Primary School', 4, 'Third Term 2013-2014', 1, 358, 15, 140, 1, 1, '2014-07-02 11:12:59', '2014-09-12 09:23:56'),
(13, 4, 'Shaibu', 'Emmanuel', '', 'stu0013', 'students/13.JPG', 'Male', '1990-11-08', 37, 'Christian', 'St. Bath Wussasa Zaria', 4, 'Third Term 2013-2014', 1, 470, 16, 140, 1, 1, '2014-07-03 11:54:53', '2014-09-12 09:23:56'),
(14, 29, 'Jafaru', 'Audu', '', 'stu0014', 'students/14.JPG', 'Male', '2010-08-13', 8, 'Traditional', 'Mallam Kato High School Kano', 4, 'Third Term 2013-2014', 1, 360, 15, 140, 3, 1, '2014-07-10 02:42:47', '2014-12-22 11:41:34'),
(15, 7, 'Judith', 'Akume', 'Bola', 'stu0015', 'students/15.JPG', 'Female', '2009-02-17', 36, 'Christian', 'St. Bath Wussasa Zaria', 4, 'Third Term 2013-2014', 1, 137, 6, 140, 2, 2, '2014-07-15 12:54:52', '2014-09-12 09:23:56'),
(16, 9, 'Joseph ', 'Addams', 'Bill ', 'stu0016', 'students/16.jpg', 'Male', '2010-06-03', 92, 'Christian', 'Saint Mary and Alfred', 4, '2rd ', 1, 349, 15, 140, 1, 6, '2014-07-22 03:53:49', '2014-09-12 09:23:56'),
(17, 8, 'Prince ', 'Kingsley', 'Edwin', 'stu0017', 'students/17.jpg', 'Male', '2014-07-20', 87, 'Traditional', 'Aquinas Comprehensive high school', 4, 'First Term 2014-2015', 1, 124, 6, 140, 4, 6, '2014-07-22 04:05:14', '2014-09-12 09:23:56'),
(18, 8, 'Drogba', 'Mercy', 'Taiwo', 'stu0018', 'students/18.jpg', 'Male', '2014-09-06', 41, 'Muslim', 'Ruddy Kiddies School', 4, 'Third Term 2013-2014', 1, 36, 2, 140, 5, 6, '2014-07-22 04:17:18', '2014-09-12 09:23:56'),
(19, 8, 'Johnson', 'Mercy', 'Dayo', 'stu0019', 'students/19.jpg', 'Male', '2014-09-06', 41, 'Muslim', 'Ruddy Kiddies School', 4, 'First Term 2014-2015', 1, 36, 2, 140, 5, 6, '2014-07-22 04:17:20', '2014-09-12 09:23:56'),
(20, 10, 'Idris', 'Abdulkareem', 'Omonla', 'stu0020', NULL, 'Male', '2011-12-10', 15, 'Traditional', 'Faith Reward Int''l School', 4, 'First Term 2014-2015', 1, 346, 15, 140, 7, 6, '2014-07-22 04:27:10', '2014-09-12 09:23:56'),
(21, 11, 'sulaimon', 'shittu', 'yemi', 'stu0021', 'students/21.jpg', 'Male', '1992-08-08', 92, 'Muslim', 'Faith Reward Int''l School', 4, '', 1, 559, 23, 140, 3, 6, '2014-09-10 01:33:06', '2014-09-12 09:23:56'),
(22, 11, 'Jamila', 'Ibrahim', 'Dabo', 'stu0022', 'students/22.png', 'Female', '2001-08-14', 11, 'Muslim', 'Efiong Topko Secondary Schoo', 4, '', 1, 324, 13, 140, 2, 6, '2014-09-10 01:35:36', '2014-09-12 09:23:56'),
(23, 12, 'MOHAAMMED', 'ISIAKA', 'INUWA', 'stu0023', 'students/23.jpg', 'Male', '1999-04-08', NULL, 'Muslim', '', 4, '', 1, 325, 13, 140, 1, 6, '2014-09-10 01:50:57', '2014-09-12 09:23:56'),
(24, 13, 'Kingsley', 'Chinaka', 'Wesley', 'stu0024', NULL, 'Male', '2014-01-27', 78, 'Christian', 'Amazing Grace Sec School ', 4, '2nd Term', 1, 222, 37, 140, 7, 6, '2014-09-10 02:11:25', '2014-09-12 09:23:56'),
(25, 14, 'Bill', 'Addams', 'Joseph', 'stu0025', NULL, 'Male', '2014-03-19', 111, 'Christian', 'His Grace School', 4, '1st Term', 1, 359, 15, 140, 5, 6, '2014-09-10 02:19:27', '2014-09-12 09:23:56'),
(26, 14, 'Natasha ', 'Eric', 'Alia', 'stu0026', 'students/26.jpg', 'Female', '1990-08-09', 106, 'Christian', 'Eagles Gathering Model Colledge', 4, '2nd Term', 1, 482, 16, 140, 6, 6, '2014-09-10 02:26:40', '2014-09-12 09:23:56'),
(27, 11, 'MARIAM', 'ITANOLA', 'MUHREEHAM', 'stu0027', 'students/27.jpg', 'Female', '1995-10-07', 86, 'Muslim', '', 4, '', 1, 564, 23, 140, 2, 6, '2014-09-10 02:42:25', '2014-09-12 09:23:56'),
(28, 6, 'MUKTAR', 'JUBRIL', 'MOHAMMED', 'stu0028', 'students/28.jpg', 'Male', '1993-04-01', 78, 'Muslim', '', 4, '', 1, 341, 15, 140, 2, 6, '2014-09-10 03:17:53', '2014-09-12 09:23:56'),
(29, 16, 'King', 'Depp', 'presh', 'stu0029', 'students/29.jpg', 'Male', '2014-10-30', 65, 'Muslim', 'Asinhow Primary School', 4, '1st Term', 1, 130, 6, 140, 5, 6, '2014-09-10 03:34:28', '2014-09-12 09:23:56'),
(30, 12, 'OLAKOJO', 'OLAWALE', 'OLANIYI', 'stu0030', 'students/30.jpg', 'Male', '1995-05-03', 108, 'Muslim', '', 4, '', 1, 490, 19, 140, 3, 6, '2014-09-10 03:35:39', '2014-09-12 09:23:56'),
(31, 16, 'Hash', 'Ado', 'Aba', 'stu0031', 'students/31.jpg', 'Male', '2012-10-29', 37, 'Traditional', 'Justarrived Secondary school', 4, '2nd Term', 1, 83, 4, 140, 3, 6, '2014-09-10 03:37:23', '2014-09-12 09:23:56'),
(32, 17, 'Maryam', 'Abdullahi', 'Natasha', 'stu0032', 'students/32.jpg', 'Female', '2014-09-21', 106, 'Muslim', 'Princess Colledge School', 4, '2nd Term', 1, 477, 16, 140, 1, 6, '2014-09-10 03:45:55', '2014-09-12 09:23:56'),
(33, 12, 'sulaimon', 'makajuola', 'abbey', 'stu0033', 'students/33.jpg', 'Male', '1992-03-04', 87, 'Muslim', '', 4, '', 1, 248, 36, 140, 2, 6, '2014-09-10 03:48:20', '2014-09-12 09:23:56'),
(34, 17, 'Gideon', 'George', 'Greg', 'stu0034', 'students/34.jpg', 'Male', '2005-03-06', 31, 'Christian', 'Unitednation primary School', 4, '2nd Term', 1, 137, 6, 140, 9, 6, '2014-09-10 03:52:17', '2014-09-12 09:23:56'),
(35, 6, 'SALAMATU', 'ABDULWAHAB', 'SALMA', 'stu0035', 'students/35.jpg', 'Male', '1991-02-13', 89, 'Muslim', '', 4, '', 1, 552, 21, 140, 3, 6, '2014-09-10 03:54:04', '2014-09-12 09:23:56'),
(36, 18, 'Favour', 'Oseni', 'Ufedo Ojo', 'stu0036', 'students/36.jpg', 'Female', '2010-11-02', 99, 'Christian', 'Ancientwords Secondary School', 4, '3rd Term', 1, 482, 16, 140, 2, 6, '2014-09-10 04:02:25', '2014-09-12 09:23:56'),
(37, 18, 'Mohammed', 'Isaka', 'Gaja', 'stu0037', 'students/37.jpg', 'Male', '2014-09-03', 81, 'Christian', 'BesTaste Comprehensive Colledge', 4, '3rd Term', 1, 274, 31, 140, 7, 6, '2014-09-10 04:10:13', '2014-09-12 09:23:56'),
(38, 8, 'Angel', 'George', 'Anita', 'stu0038', 'students/38.jpg', 'Female', '1995-05-06', 45, 'Muslim', 'Precious primary school', 4, '3rd Term', 1, 249, 36, 140, 4, 6, '2014-09-11 10:05:09', '2014-09-12 09:23:56'),
(39, 20, 'Olaolu ', 'Bimbo', 'Tobi', 'stu0039', 'students/39.jpg', 'Female', '1994-07-08', 79, 'Christian', 'Redrose school', 4, '1st Term', 1, 496, 19, 140, 2, 6, '2014-09-11 10:17:52', '2014-09-12 09:23:56'),
(40, 20, 'Remilekun', 'Olamiposi', 'Kikelomo', 'stu0040', 'students/40.jpg', 'Female', '2010-08-09', 108, 'Traditional', 'Santa Maria Private School', 4, '3rd Term', 1, 585, 22, 140, 5, 6, '2014-09-11 10:31:25', '2014-09-12 09:23:56'),
(41, 21, 'Muhammed', 'Amir', 'inuwa', 'stu0041', 'students/41.jpg', 'Male', '2014-12-05', NULL, 'Muslim', '', 4, '', 1, 149, 7, 140, 4, 6, '2014-09-11 10:42:15', '2014-10-17 08:30:12'),
(42, 12, 'ZAINAB', 'LUKAMAN', 'HAJIA', 'stu0042', 'students/42.jpg', 'Female', '1992-04-22', 100, 'Muslim', '', 4, '1st term', 1, 239, 36, 140, 3, 6, '2014-09-11 11:16:59', '2014-09-12 09:23:56'),
(43, 12, 'ADEYERI ', 'FOLAGBADE', 'FOLLY', 'stu0043', 'students/43.jpg', 'Male', '1992-05-15', 106, 'Christian', '', 4, '', 1, 253, 36, 140, 5, 6, '2014-09-11 12:07:58', '2014-09-12 09:23:56'),
(44, 12, 'USMAN', 'AMINU', 'MOHAMMED', 'stu0044', 'students/44.jpg', 'Male', '1994-06-23', 79, 'Muslim', '', 4, '', 1, 320, 13, 140, 5, 6, '2014-09-11 12:12:48', '2014-09-12 09:23:56'),
(45, 6, 'LATEEF', 'ANIFOWOSHE', 'LATICE', 'stu0045', 'students/45.jpg', 'Female', '1993-04-28', 95, 'Muslim', '', 4, '', 1, 489, 19, 140, 3, 6, '2014-09-11 12:16:27', '2014-09-12 09:23:56'),
(46, 12, 'ABUBAKAR', 'SANNI', 'SHGAMU', 'stu0046', 'students/46.jpg', 'Male', '1995-09-20', 92, 'Muslim', '', 4, '', 1, 399, 17, 140, 7, 6, '2014-09-11 12:28:14', '2014-09-12 09:23:56'),
(47, 22, 'Susan ', 'Elikwu', 'Chinenye', 'stu0047', 'students/47.jpg', 'Female', '1991-06-12', 95, 'Christian', 'Sanya grammar school', 4, '1st Term', 1, 190, 9, 140, 6, 6, '2014-09-11 12:33:57', '2014-09-12 09:23:56'),
(48, 23, 'Muktar', 'Usman', 'Kelvin', 'stu0048', 'students/48.jpg', 'Male', '2005-03-02', 29, 'Muslim', 'Christcares school', 4, '1st Term', 1, 339, 13, 140, 7, 6, '2014-09-11 12:47:14', '2014-09-12 09:23:56'),
(49, 24, 'MOHAMMED', 'MAHMUD', 'INUWA', 'stu0049', 'students/49.jpg', 'Male', '1989-09-28', 110, 'Muslim', '', 4, '', 1, 320, 13, 140, 3, 6, '2014-09-11 01:07:05', '2014-09-12 09:23:56'),
(50, 25, 'Blessing', 'Adama', 'Chegbe', 'stu0050', 'students/50.jpg', 'Female', '2005-05-05', 39, 'Muslim', 'High School Colledge', 4, '2nd Term', 1, 199, 9, 140, 2, 6, '2014-09-11 01:16:44', '2014-09-12 09:23:56'),
(51, 25, 'Anifowoshe', 'Lateef', 'Akonny', 'stu0051', 'students/51.JPG', 'Male', '1993-06-06', 39, 'Muslim', 'Faith Reward int''l School', 4, '3rd Term', 1, 267, 11, 140, 7, 6, '2014-09-11 01:20:34', '2014-09-12 09:23:56'),
(52, 26, 'James', 'Joshua', 'Jack', 'stu0052', 'students/52.jpg', 'Male', '2009-05-06', 51, 'Christian', 'Precious kids School', 4, '2nd Term', 1, 81, 4, 140, 1, 6, '2014-09-11 01:34:50', '2014-09-12 09:23:56'),
(53, 27, 'Chidinma', 'Ogochukwu', 'Chigozie', 'stu0053', 'students/53.jpg', 'Female', '2009-08-08', 38, 'Christian', 'Saint John primary school', 4, '2nd Term', 1, 286, 33, 140, 8, 6, '2014-09-11 01:46:01', '2014-09-12 09:23:56'),
(54, 16, 'Gideon', 'farrida', '', 'stu0054', 'students/54.jpg', 'Female', '2014-09-03', 40, 'Christian', 'Precios love school', 4, '2nd Term', 1, 273, 31, 140, 8, 6, '2014-09-11 01:58:07', '2014-09-12 09:23:56'),
(55, 24, 'MOHAMMED', 'YUSUF', 'INUWA', 'stu0055', 'students/55.jpg', 'Male', '1970-01-01', 96, 'Muslim', '', 4, '', 1, 626, 24, 140, 3, 2, '2014-10-24 10:22:29', '2014-10-24 09:22:29'),
(59, 1, 'Emmanuel', 'Joker', 'Bull', 'stu0059', 'students/59.jpg', 'Male', '2000-11-01', 106, NULL, NULL, 4, 'Third Term 2013-2014', 1, 56, 3, 140, 6, 2, '2014-10-24 10:24:40', '2014-10-24 09:24:40'),
(60, 16, 'Florence', 'Mary', 'John', 'stu0060', 'students/60.jpg', 'Female', '2011-04-15', 40, NULL, NULL, 4, 'Third Term', 1, 134, 6, 140, 2, 2, '2014-10-24 10:26:23', '2014-10-24 09:26:23'),
(61, 13, 'Judith', 'John', 'Grace', 'stu0061', NULL, 'Female', '2005-11-11', 10, NULL, NULL, 4, 'Second Term 2014-2015', 1, 288, 12, 140, 1, 2, '2014-11-17 01:14:45', '2014-11-17 12:14:45'),
(62, 3, 'Mariah', 'Usman', 'Fade', 'stu0062', NULL, 'Female', '1995-07-05', 106, NULL, NULL, 4, 'Second Term 2014-2015', 1, 19, 2, 140, 3, 2, '2014-11-17 10:52:14', '2014-11-17 09:52:14'),
(63, 9, 'JohnBull', 'Desmond', 'Jude', 'stu0063', 'students/63.jpg', 'Male', '2007-06-04', 106, NULL, NULL, 4, 'First Term 2014-2015', 1, 270, 11, 140, 2, 4, '2015-03-12 10:39:38', '2015-03-12 09:39:38');

-- --------------------------------------------------------

--
-- Table structure for table `students_classes`
--

CREATE TABLE IF NOT EXISTS `students_classes` (
`student_class_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `academic_year_id` int(11) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=59 ;

--
-- Dumping data for table `students_classes`
--

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
(57, 62, 106, 2),
(58, 63, 106, 2);

-- --------------------------------------------------------

--
-- Stand-in structure for view `students_classlevelviews`
--
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
-- --------------------------------------------------------

--
-- Stand-in structure for view `students_paymentviews`
--
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
-- --------------------------------------------------------

--
-- Stand-in structure for view `students_subjectsviews`
--
CREATE TABLE IF NOT EXISTS `students_subjectsviews` (
`student_id` int(11)
,`subject_classlevel_id` int(11)
,`student_name` varchar(153)
,`student_no` varchar(50)
);
-- --------------------------------------------------------

--
-- Table structure for table `subject_classlevels`
--

CREATE TABLE IF NOT EXISTS `subject_classlevels` (
`subject_classlevel_id` int(11) NOT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `classlevel_id` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `academic_term_id` int(11) DEFAULT NULL,
  `examstatus_id` int(11) DEFAULT '2'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=38 ;

--
-- Dumping data for table `subject_classlevels`
--

INSERT INTO `subject_classlevels` (`subject_classlevel_id`, `subject_id`, `classlevel_id`, `class_id`, `academic_term_id`, `examstatus_id`) VALUES
(1, 14, 12, 84, 4, 2),
(2, 12, 16, NULL, 4, 1),
(3, 7, 2, NULL, 4, 2),
(4, 15, 16, 106, 4, 2),
(5, 1, 1, NULL, 4, 2),
(6, 9, 2, 8, 4, 2),
(7, 20, 4, 22, 4, 2),
(9, 21, 6, NULL, 4, 1),
(10, 25, 2, NULL, 4, 1),
(11, 16, 2, 9, 4, 1),
(12, 18, 2, NULL, 4, 1),
(13, 7, 6, NULL, 4, 1),
(14, 7, 3, 15, 4, 2),
(15, 14, 16, NULL, 4, 1),
(16, 14, 2, NULL, 4, 1),
(17, 13, 2, NULL, 4, 1),
(18, 15, 2, NULL, 4, 1),
(19, 8, 2, NULL, 4, 1),
(20, 14, 2, NULL, 5, 1),
(21, 13, 2, NULL, 5, 1),
(22, 15, 2, NULL, 5, 1),
(23, 8, 2, NULL, 5, 1),
(24, 14, 6, -1, 4, 1),
(36, 23, 6, NULL, 4, 1),
(37, 25, 2, 8, 4, 1);

-- --------------------------------------------------------

--
-- Stand-in structure for view `subject_classlevelviews`
--
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
-- --------------------------------------------------------

--
-- Table structure for table `subject_groups`
--

CREATE TABLE IF NOT EXISTS `subject_groups` (
`subject_group_id` int(3) NOT NULL,
  `subject_group` varchar(50) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=8 ;

--
-- Dumping data for table `subject_groups`
--

INSERT INTO `subject_groups` (`subject_group_id`, `subject_group`) VALUES
(1, 'Art'),
(2, 'Elementry'),
(3, 'General'),
(4, 'Languages'),
(5, 'Others'),
(6, 'Religion'),
(7, 'Science');

-- --------------------------------------------------------

--
-- Table structure for table `subject_students_registers`
--

CREATE TABLE IF NOT EXISTS `subject_students_registers` (
  `student_id` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `subject_classlevel_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `subject_students_registers`
--

INSERT INTO `subject_students_registers` (`student_id`, `class_id`, `subject_classlevel_id`) VALUES
(5, NULL, 13),
(12, NULL, 13),
(13, NULL, 13),
(4, NULL, 14),
(3, NULL, 11),
(11, NULL, 11),
(1, NULL, 12),
(9, NULL, 12),
(10, NULL, 12),
(11, NULL, 12),
(1, NULL, 3),
(3, NULL, 3),
(9, NULL, 3),
(10, NULL, 3),
(11, NULL, 3),
(14, NULL, 3),
(6, NULL, 15),
(1, NULL, 16),
(9, NULL, 16),
(10, NULL, 16),
(11, NULL, 16),
(14, NULL, 16),
(1, NULL, 17),
(9, NULL, 17),
(10, NULL, 17),
(11, NULL, 17),
(14, NULL, 17),
(22, NULL, 17),
(1, NULL, 18),
(9, NULL, 18),
(10, NULL, 18),
(11, NULL, 18),
(14, NULL, 18),
(22, NULL, 18),
(1, NULL, 19),
(9, NULL, 19),
(10, NULL, 19),
(11, NULL, 19),
(14, NULL, 19),
(22, NULL, 19),
(5, 36, 36),
(12, 36, 36),
(13, 37, 36),
(15, 36, 36),
(18, 41, 36),
(19, 41, 36),
(31, 37, 36),
(32, 37, 36),
(50, 39, 36),
(51, 39, 36),
(53, 38, 36),
(54, 40, 36),
(1, 8, 37),
(9, 8, 37),
(10, 8, 37),
(14, 8, 37);

-- --------------------------------------------------------

--
-- Table structure for table `subjects`
--

CREATE TABLE IF NOT EXISTS `subjects` (
`subject_id` int(3) NOT NULL,
  `subject_name` varchar(50) DEFAULT NULL,
  `subject_group_id` int(11) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=27 ;

--
-- Dumping data for table `subjects`
--

INSERT INTO `subjects` (`subject_id`, `subject_name`, `subject_group_id`) VALUES
(1, 'Business Studies', 1),
(2, 'Creative Arts', 1),
(3, 'English Literature', 1),
(4, 'Home Economics', 1),
(5, 'Music', 1),
(6, 'Social Studies', 1),
(7, 'Drawing', 2),
(8, 'Phisical Education', 2),
(9, 'Quantitative Aptitude', 2),
(10, 'Reading', 2),
(11, 'Spelling/Dictation', 2),
(12, 'Vocational Aptitude', 2),
(13, 'Writing', 2),
(14, 'English', 3),
(15, 'Mathematics', 3),
(16, 'French', 4),
(17, 'Hausa Language', 4),
(18, 'Igbo Language', 4),
(19, 'Yoruba Language', 4),
(20, 'Christain Religious knowledge', 6),
(21, 'Islamic Religious knowledge', 6),
(22, 'Agriculture', 7),
(23, 'Computer Studies', 7),
(24, 'Integrated Science', 7),
(25, 'Introductory Technology', 7),
(26, 'Science', 7);

-- --------------------------------------------------------

--
-- Table structure for table `teachers_classes`
--

CREATE TABLE IF NOT EXISTS `teachers_classes` (
`teacher_class_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `academic_year_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=10 ;

--
-- Dumping data for table `teachers_classes`
--

INSERT INTO `teachers_classes` (`teacher_class_id`, `employee_id`, `class_id`, `academic_year_id`, `created_at`, `updated_at`) VALUES
(1, 4, 37, 2, '2014-10-17 11:41:19', '2014-10-17 10:43:49'),
(2, 4, 8, 2, '2014-10-17 11:41:29', '2014-10-17 10:43:49'),
(3, 2, 9, 2, '2014-10-17 11:48:24', '2014-10-17 10:48:24'),
(6, 2, 36, 2, '2014-10-17 11:55:34', '2014-10-17 10:55:46'),
(7, 6, 39, 2, '2014-10-17 02:06:25', '0000-00-00 00:00:00'),
(8, 6, 41, 2, '2014-10-17 02:06:30', '0000-00-00 00:00:00'),
(9, 6, 106, 2, '2014-11-06 09:43:55', '2014-11-06 08:44:06');

-- --------------------------------------------------------

--
-- Stand-in structure for view `teachers_classviews`
--
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
-- --------------------------------------------------------

--
-- Table structure for table `teachers_subjects`
--

CREATE TABLE IF NOT EXISTS `teachers_subjects` (
`teachers_subjects_id` int(11) NOT NULL,
  `employee_id` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `subject_classlevel_id` int(11) DEFAULT NULL,
  `assign_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=25 ;

--
-- Dumping data for table `teachers_subjects`
--

INSERT INTO `teachers_subjects` (`teachers_subjects_id`, `employee_id`, `class_id`, `subject_classlevel_id`, `assign_date`) VALUES
(1, 5, 106, 4, '0000-00-00 00:00:00'),
(2, 4, 84, 1, '0000-00-00 00:00:00'),
(3, 4, 11, 12, '0000-00-00 00:00:00'),
(4, 5, 9, 11, '0000-00-00 00:00:00'),
(5, 1, 22, 7, '2014-07-08 11:31:01'),
(6, 3, 8, 6, '2014-07-08 11:31:27'),
(7, 1, 8, 3, '2014-07-08 04:46:44'),
(8, 2, 9, 3, '2014-07-08 04:50:53'),
(9, 1, 9, 12, '2014-07-26 10:58:47'),
(10, 2, 13, 12, '2014-07-26 11:44:21'),
(11, 2, 15, 14, '2014-09-04 08:15:51'),
(12, 9, 8, 17, '2014-09-23 03:19:22'),
(13, 2, 8, 10, '2014-10-15 10:11:27'),
(14, 2, 8, 16, '2014-10-15 10:11:38'),
(15, 2, 39, 36, '2014-10-16 07:39:13'),
(16, 4, 36, 13, '2014-10-23 07:53:02'),
(17, 4, 36, 24, '2014-10-23 07:53:32'),
(18, 4, 37, 36, '2014-10-23 07:53:38'),
(19, 4, 39, 24, '2014-10-23 07:54:06'),
(20, 4, 8, 37, '2014-10-23 08:31:17'),
(21, 6, 37, 24, '2014-11-06 02:26:20'),
(22, 6, 41, 24, '2014-11-06 02:26:24'),
(23, 6, 38, 36, '2014-11-06 02:27:14'),
(24, 6, 38, 24, '2014-11-06 02:27:22');

-- --------------------------------------------------------

--
-- Stand-in structure for view `teachers_subjectsviews`
--
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
-- --------------------------------------------------------

--
-- Table structure for table `user_roles`
--

CREATE TABLE IF NOT EXISTS `user_roles` (
`user_role_id` int(3) unsigned NOT NULL,
  `user_role` varchar(50) DEFAULT NULL,
  `group_alias` varchar(30) NOT NULL DEFAULT 'web_users'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

--
-- Dumping data for table `user_roles`
--

INSERT INTO `user_roles` (`user_role_id`, `user_role`, `group_alias`) VALUES
(1, 'Sponsor', 'spn_users'),
(2, 'Student', 'spn_users'),
(3, 'Employee', 'emp_users'),
(4, 'ICT', 'ict_users'),
(5, 'Admin', 'app_users'),
(6, 'Super Admin', 'adm_users');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE IF NOT EXISTS `users` (
`user_id` int(10) unsigned NOT NULL,
  `username` varchar(70) NOT NULL,
  `password` varchar(150) NOT NULL,
  `display_name` varchar(100) DEFAULT NULL,
  `type_id` int(11) NOT NULL,
  `image_url` varchar(50) DEFAULT NULL,
  `user_role_id` int(11) NOT NULL,
  `group_alias` varchar(20) NOT NULL DEFAULT 'web_users',
  `status_id` int(11) NOT NULL DEFAULT '1',
  `created_by` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=6 ;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `password`, `display_name`, `type_id`, `image_url`, `user_role_id`, `group_alias`, `status_id`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'emp0002', '$2a$10$hcl7ySmI/9NxTnEMp6GFQOA8dnJezUk/Kn7OQqjphpQEqKmLy2oUe', 'GEORGE, UCHE', 2, 'employees/2.jpg', 6, 'adm_users', 1, 2, '2014-06-16 02:39:58', '2015-03-11 12:06:22'),
(2, 'spn0001', '$2a$10$uLb3awX5tZDRLz4PU/WGLuCCWi5duSkO8BijIpdBVy83GHbiXSUmq', 'KAYOH, CHINA', 1, 'sponsors/1.jpg', 1, 'spn_users', 1, 2, '2014-07-17 11:14:00', '2015-03-11 18:48:14'),
(3, 'emp0006', '$2a$10$QG2RqGT8ZAMHXaPdEunG4OUcH4Sez52PbRO.DY1jmVvZCj4wrBLcW', 'KINGSLEY, CHINAKA', 6, 'employees/6.JPG', 3, 'emp_users', 1, 2, '2014-10-14 01:43:13', '2014-10-15 08:07:53'),
(4, 'emp0004', '$2a$10$oncEz7DKJm4EqJUQYn/GmuTpz0JLLaMg.KgqBuKUyM2/vpGkpYXT2', 'BOLA, YUSRAH INUA', 4, 'employees/4.jpg', 4, 'ict_users', 1, 4, '2014-06-24 04:01:20', '2015-03-04 11:22:12'),
(5, 'spn0033', '$2a$10$2mmZphckyEYGq6DR78B.XOn/f7dxv09BnjM8D/URqw9FpFcPtit8i', 'OBINNA EKWUEME', 33, 'sponsors/33.jpg', 1, 'spn_users', 1, 2, '2015-03-10 03:07:44', '2015-03-11 12:36:10');

-- --------------------------------------------------------

--
-- Structure for view `attend_headerviews`
--
DROP TABLE IF EXISTS `attend_headerviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `attend_headerviews` AS select `a`.`attend_id` AS `attend_id`,`a`.`class_id` AS `class_id`,`a`.`employee_id` AS `employee_id`,`a`.`academic_term_id` AS `academic_term_id`,`a`.`attend_date` AS `attend_date`,`b`.`class_name` AS `class_name`,`b`.`classlevel_id` AS `classlevel_id`,`c`.`academic_term` AS `academic_term`,`c`.`academic_year_id` AS `academic_year_id`,concat(ucase(`d`.`first_name`),' ',`d`.`other_name`) AS `head_tutor` from (((`attends` `a` join `classrooms` `b` on((`a`.`class_id` = `b`.`class_id`))) join `academic_terms` `c` on((`a`.`academic_term_id` = `c`.`academic_term_id`))) join `employees` `d` on((`a`.`employee_id` = `d`.`employee_id`)));

-- --------------------------------------------------------

--
-- Structure for view `exam_subjectviews`
--
DROP TABLE IF EXISTS `exam_subjectviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `exam_subjectviews` AS select `a`.`exam_id` AS `exam_id`,`a`.`exam_desc` AS `exam_desc`,`a`.`class_id` AS `class_id`,`f`.`class_name` AS `class_name`,`c`.`subject_name` AS `subject_name`,`b`.`subject_id` AS `subject_id`,`a`.`subject_classlevel_id` AS `subject_classlevel_id`,`a`.`weightageCA1` AS `weightageCA1`,`a`.`weightageCA2` AS `weightageCA2`,`a`.`weightageExam` AS `weightageExam`,`a`.`employee_id` AS `setup_by`,`a`.`exammarked_status_id` AS `exammarked_status_id`,`a`.`setup_date` AS `setup_date`,`f`.`classlevel_id` AS `classlevel_id`,`g`.`classlevel` AS `classlevel`,`b`.`academic_term_id` AS `academic_term_id`,`d`.`academic_term` AS `academic_term`,`d`.`academic_year_id` AS `academic_year_id`,`e`.`academic_year` AS `academic_year` from (((((`exams` `a` left join (`classlevels` `g` join `classrooms` `f` on((`f`.`classlevel_id` = `g`.`classlevel_id`))) on((`a`.`class_id` = `f`.`class_id`))) join `subject_classlevels` `b` on((`a`.`subject_classlevel_id` = `b`.`subject_classlevel_id`))) join `subjects` `c` on((`b`.`subject_id` = `c`.`subject_id`))) join `academic_terms` `d` on((`b`.`academic_term_id` = `d`.`academic_term_id`))) join `academic_years` `e` on((`d`.`academic_year_id` = `e`.`academic_year_id`)));

-- --------------------------------------------------------

--
-- Structure for view `examsdetails_reportviews`
--
DROP TABLE IF EXISTS `examsdetails_reportviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `examsdetails_reportviews` AS select `exams`.`exam_id` AS `exam_id`,`subject_classlevels`.`subject_id` AS `subject_id`,`subject_classlevels`.`classlevel_id` AS `classlevel_id`,`classrooms`.`class_id` AS `class_id`,`students`.`student_id` AS `student_id`,`subjects`.`subject_name` AS `subject_name`,`classrooms`.`class_name` AS `class_name`,concat(ucase(`students`.`first_name`),' ',lcase(`students`.`surname`),' ',lcase(`students`.`other_name`)) AS `student_fullname`,`exam_details`.`ca1` AS `ca1`,`exam_details`.`ca2` AS `ca2`,`exam_details`.`exam` AS `exam`,`exams`.`weightageCA1` AS `weightageCA1`,`exams`.`weightageCA2` AS `weightageCA2`,`exams`.`weightageExam` AS `weightageExam`,`academic_terms`.`academic_term_id` AS `academic_term_id`,`academic_terms`.`academic_term` AS `academic_term`,`exams`.`exammarked_status_id` AS `exammarked_status_id`,`academic_terms`.`academic_year_id` AS `academic_year_id`,`academic_years`.`academic_year` AS `academic_year`,`classlevels`.`classlevel` AS `classlevel`,`classlevels`.`classgroup_id` AS `classgroup_id` from (((((((((`exams` join `exam_details` on((`exams`.`exam_id` = `exam_details`.`exam_id`))) join `subject_classlevels` on((`exams`.`subject_classlevel_id` = `subject_classlevels`.`subject_classlevel_id`))) join `subjects` on((`subject_classlevels`.`subject_id` = `subjects`.`subject_id`))) join `students` on((`exam_details`.`student_id` = `students`.`student_id`))) join `academic_terms` on((`subject_classlevels`.`academic_term_id` = `academic_terms`.`academic_term_id`))) join `academic_years` on((`academic_years`.`academic_year_id` = `academic_terms`.`academic_year_id`))) join `classlevels` on((`subject_classlevels`.`classlevel_id` = `classlevels`.`classlevel_id`))) join `students_classes` on((`students`.`student_id` = `students_classes`.`student_id`))) join `classrooms` on((`students_classes`.`class_id` = `classrooms`.`class_id`)));

-- --------------------------------------------------------

--
-- Structure for view `student_feesqueryviews`
--
DROP TABLE IF EXISTS `student_feesqueryviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `student_feesqueryviews` AS select `orders`.`order_id` AS `order_id`,`item_bills`.`price` AS `price`,`orders`.`process_item_id` AS `process_item_id`,`item_bills`.`item_id` AS `item_id`,`items`.`item_name` AS `item_name`,`orders`.`academic_term_id` AS `academic_term_id`,`academic_terms`.`academic_term` AS `academic_term`,`students_classlevelviews`.`student_name` AS `student_name`,`students_classlevelviews`.`student_id` AS `student_id`,concat(ucase(`sponsors`.`first_name`),' ',`sponsors`.`other_name`) AS `sponsor_name`,`sponsors`.`sponsor_id` AS `sponsor_id`,`students_classlevelviews`.`class_name` AS `class_name`,`students_classlevelviews`.`class_id` AS `class_id`,`students_classlevelviews`.`classlevel` AS `classlevel`,`students_classlevelviews`.`classlevel_id` AS `classlevel_id`,`students_classlevelviews`.`academic_year_id` AS `academic_year_id`,`students_classlevelviews`.`academic_year` AS `academic_year`,`items`.`item_type_id` AS `item_type_id`,`items`.`item_status_id` AS `item_status_id`,`item_types`.`item_type` AS `item_type` from ((((((`item_types` join `items` on((`item_types`.`item_type_id` = `items`.`item_type_id`))) join `item_bills` on((`item_bills`.`item_id` = `items`.`item_id`))) join `students_classlevelviews` on((`item_bills`.`classlevel_id` = `students_classlevelviews`.`classlevel_id`))) join `sponsors` on((`sponsors`.`sponsor_id` = `students_classlevelviews`.`sponsor_id`))) join `orders` on((`orders`.`student_id` = `students_classlevelviews`.`student_id`))) join `academic_terms` on((`academic_terms`.`academic_term_id` = `orders`.`academic_term_id`)));

-- --------------------------------------------------------

--
-- Structure for view `student_feesviews`
--
DROP TABLE IF EXISTS `student_feesviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `student_feesviews` AS select concat(ucase(`a`.`first_name`),' ',`a`.`surname`,' ',`a`.`other_name`) AS `student_name`,`a`.`student_id` AS `student_id`,`a`.`student_no` AS `student_no`,concat(ucase(`b`.`first_name`),' ',`b`.`other_name`) AS `sponsor_name`,`b`.`sponsor_id` AS `sponsor_id`,`c`.`salutation_name` AS `salutation_name`,`f`.`order_id` AS `order_id`,`h`.`price` AS `price`,`h`.`quantity` AS `quantity`,(`h`.`quantity` * `h`.`price`) AS `subtotal`,`h`.`item_id` AS `item_id`,`i`.`item_name` AS `item_name`,`i`.`item_description` AS `item_description`,`f`.`academic_term_id` AS `academic_term_id`,`g`.`academic_term` AS `academic_term`,`f`.`status_id` AS `order_status_id`,`l`.`class_id` AS `class_id`,`m`.`class_name` AS `class_name`,`m`.`classlevel_id` AS `classlevel_id`,`n`.`classlevel` AS `classlevel`,`i`.`item_type_id` AS `item_type_id`,`j`.`item_type` AS `item_type`,`a`.`image_url` AS `image_url`,`g`.`academic_year_id` AS `academic_year_id`,`k`.`academic_year` AS `academic_year`,`d`.`student_status_id` AS `student_status_id`,`d`.`student_status` AS `student_status` from ((((((((((((`students` `a` join `sponsors` `b` on((`a`.`sponsor_id` = `b`.`sponsor_id`))) join `salutations` `c` on((`c`.`salutation_id` = `b`.`salutation_id`))) join `student_status` `d` on((`a`.`student_status_id` = `d`.`student_status_id`))) join `orders` `f` on((`a`.`student_id` = `f`.`student_id`))) join `academic_terms` `g` on((`f`.`academic_term_id` = `g`.`academic_term_id`))) join `order_items` `h` on((`f`.`order_id` = `h`.`order_id`))) join `items` `i` on((`h`.`item_id` = `i`.`item_id`))) join `item_types` `j` on((`i`.`item_type_id` = `j`.`item_type_id`))) join `academic_years` `k` on((`g`.`academic_year_id` = `k`.`academic_year_id`))) join `students_classes` `l` on(((`a`.`student_id` = `l`.`student_id`) and (`g`.`academic_year_id` = `l`.`academic_year_id`)))) join `classrooms` `m` on((`l`.`class_id` = `m`.`class_id`))) join `classlevels` `n` on((`m`.`classlevel_id` = `n`.`classlevel_id`)));

-- --------------------------------------------------------

--
-- Structure for view `students_classlevelviews`
--
DROP TABLE IF EXISTS `students_classlevelviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `students_classlevelviews` AS select concat(ucase(`students`.`first_name`),' ',`students`.`surname`,' ',`students`.`other_name`) AS `student_name`,`students`.`student_no` AS `student_no`,`classrooms`.`class_name` AS `class_name`,`classrooms`.`class_id` AS `class_id`,`students`.`student_id` AS `student_id`,`classlevels`.`classlevel` AS `classlevel`,`classrooms`.`classlevel_id` AS `classlevel_id`,`students`.`sponsor_id` AS `sponsor_id`,concat(ucase(`sponsors`.`first_name`),' ',`sponsors`.`other_name`) AS `sponsor_name`,`students_classes`.`academic_year_id` AS `academic_year_id`,`academic_years`.`academic_year` AS `academic_year`,`students`.`student_status_id` AS `student_status_id` from (((((`students` join `students_classes` on((`students_classes`.`student_id` = `students`.`student_id`))) join `classrooms` on((`students_classes`.`class_id` = `classrooms`.`class_id`))) join `classlevels` on((`classlevels`.`classlevel_id` = `classrooms`.`classlevel_id`))) join `academic_years` on((`students_classes`.`academic_year_id` = `academic_years`.`academic_year_id`))) join `sponsors` on((`students`.`sponsor_id` = `sponsors`.`sponsor_id`)));

-- --------------------------------------------------------

--
-- Structure for view `students_paymentviews`
--
DROP TABLE IF EXISTS `students_paymentviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `students_paymentviews` AS select `a`.`order_id` AS `order_id`,`a`.`academic_term_id` AS `academic_term_id`,`a`.`status_id` AS `status_id`,(case `a`.`status_id` when 1 then 'Paid' when 2 then 'Not Paid' end) AS `payment_status`,`c`.`academic_term` AS `academic_term`,`b`.`student_name` AS `student_name`,`b`.`student_no` AS `student_no`,`b`.`class_name` AS `class_name`,`b`.`class_id` AS `class_id`,`b`.`student_id` AS `student_id`,`b`.`classlevel` AS `classlevel`,`b`.`classlevel_id` AS `classlevel_id`,`b`.`sponsor_id` AS `sponsor_id`,`b`.`sponsor_name` AS `sponsor_name`,`b`.`academic_year_id` AS `academic_year_id`,`b`.`academic_year` AS `academic_year`,`b`.`student_status_id` AS `student_status_id` from ((`orders` `a` join `students_classlevelviews` `b` on((`a`.`student_id` = `b`.`student_id`))) join `academic_terms` `c` on(((`a`.`academic_term_id` = `c`.`academic_term_id`) and (`c`.`academic_year_id` = `b`.`academic_year_id`)))) where (`a`.`process_item_id` is not null);

-- --------------------------------------------------------

--
-- Structure for view `students_subjectsviews`
--
DROP TABLE IF EXISTS `students_subjectsviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `students_subjectsviews` AS select `a`.`student_id` AS `student_id`,`a`.`subject_classlevel_id` AS `subject_classlevel_id`,concat(ucase(`b`.`first_name`),', ',`b`.`surname`,' ',`b`.`other_name`) AS `student_name`,`b`.`student_no` AS `student_no` from (`subject_students_registers` `a` join `students` `b` on((`a`.`student_id` = `b`.`student_id`)));

-- --------------------------------------------------------

--
-- Structure for view `subject_classlevelviews`
--
DROP TABLE IF EXISTS `subject_classlevelviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `subject_classlevelviews` AS select `classrooms`.`class_name` AS `class_name`,`subjects`.`subject_name` AS `subject_name`,`subjects`.`subject_id` AS `subject_id`,`classrooms`.`class_id` AS `class_id`,`classlevels`.`classlevel_id` AS `classlevel_id`,`subject_classlevels`.`subject_classlevel_id` AS `subject_classlevel_id`,`classlevels`.`classlevel` AS `classlevel`,`subject_classlevels`.`examstatus_id` AS `examstatus_id`,(case `subject_classlevels`.`examstatus_id` when 1 then 'Exam Already Setup' when 2 then 'Exam Not Setup' end) AS `exam_status`,`subject_classlevels`.`academic_term_id` AS `academic_term_id`,`academic_terms`.`academic_term` AS `academic_term`,`academic_terms`.`academic_year_id` AS `academic_year_id`,`academic_years`.`academic_year` AS `academic_year` from (((((`subject_classlevels` join `academic_terms` on((`subject_classlevels`.`academic_term_id` = `academic_terms`.`academic_term_id`))) join `academic_years` on((`academic_terms`.`academic_year_id` = `academic_years`.`academic_year_id`))) left join `classrooms` on((`subject_classlevels`.`class_id` = `classrooms`.`class_id`))) left join `classlevels` on((`subject_classlevels`.`classlevel_id` = `classlevels`.`classlevel_id`))) left join `subjects` on((`subject_classlevels`.`subject_id` = `subjects`.`subject_id`)));

-- --------------------------------------------------------

--
-- Structure for view `teachers_classviews`
--
DROP TABLE IF EXISTS `teachers_classviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `teachers_classviews` AS select `b`.`teacher_class_id` AS `teacher_class_id`,`b`.`employee_id` AS `employee_id`,`b`.`class_id` AS `class_id`,`b`.`academic_year_id` AS `academic_year_id`,`b`.`created_at` AS `created_at`,`b`.`updated_at` AS `updated_at`,concat(ucase(`a`.`first_name`),', ',`a`.`other_name`) AS `employee_name`,`a`.`status_id` AS `status_id`,`c`.`class_name` AS `class_name`,`c`.`classlevel_id` AS `classlevel_id`,`d`.`academic_year` AS `academic_year` from (((`employees` `a` join `teachers_classes` `b` on((`a`.`employee_id` = `b`.`employee_id`))) join `classrooms` `c` on((`b`.`class_id` = `c`.`class_id`))) join `academic_years` `d` on((`b`.`academic_year_id` = `d`.`academic_year_id`)));

-- --------------------------------------------------------

--
-- Structure for view `teachers_subjectsviews`
--
DROP TABLE IF EXISTS `teachers_subjectsviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `teachers_subjectsviews` AS select `b`.`teachers_subjects_id` AS `teachers_subjects_id`,`b`.`employee_id` AS `employee_id`,`b`.`class_id` AS `class_id`,`d`.`subject_id` AS `subject_id`,`f`.`subject_name` AS `subject_name`,`b`.`subject_classlevel_id` AS `subject_classlevel_id`,`b`.`assign_date` AS `assign_date`,`a`.`class_name` AS `class_name`,concat(ucase(`c`.`first_name`),', ',`c`.`other_name`) AS `employee_name`,`c`.`status_id` AS `status_id`,`d`.`academic_term_id` AS `academic_term_id`,`e`.`academic_term` AS `academic_term` from (((((`classrooms` `a` join `teachers_subjects` `b` on((`a`.`class_id` = `b`.`class_id`))) join `employees` `c` on((`c`.`employee_id` = `b`.`employee_id`))) join `subject_classlevels` `d` on((`d`.`subject_classlevel_id` = `b`.`subject_classlevel_id`))) join `academic_terms` `e` on((`e`.`academic_term_id` = `d`.`academic_term_id`))) join `subjects` `f` on((`f`.`subject_id` = `d`.`subject_id`)));

--
-- Indexes for dumped tables
--

--
-- Indexes for table `academic_terms`
--
ALTER TABLE `academic_terms`
 ADD PRIMARY KEY (`academic_term_id`), ADD KEY `academic_year_id` (`academic_year_id`), ADD KEY `term_status_id` (`term_status_id`), ADD KEY `term_type_id` (`term_type_id`);

--
-- Indexes for table `academic_years`
--
ALTER TABLE `academic_years`
 ADD PRIMARY KEY (`academic_year_id`), ADD KEY `year_status_id` (`year_status_id`);

--
-- Indexes for table `acos`
--
ALTER TABLE `acos`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `aros`
--
ALTER TABLE `aros`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `aros_acos`
--
ALTER TABLE `aros_acos`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `ARO_ACO_KEY` (`aro_id`,`aco_id`);

--
-- Indexes for table `assessments`
--
ALTER TABLE `assessments`
 ADD PRIMARY KEY (`assessment_id`);

--
-- Indexes for table `attend_details`
--
ALTER TABLE `attend_details`
 ADD KEY `student_id` (`student_id`,`attend_id`);

--
-- Indexes for table `attends`
--
ALTER TABLE `attends`
 ADD PRIMARY KEY (`attend_id`), ADD KEY `class_id` (`class_id`,`employee_id`,`academic_term_id`);

--
-- Indexes for table `classgroups`
--
ALTER TABLE `classgroups`
 ADD PRIMARY KEY (`classgroup_id`);

--
-- Indexes for table `classlevels`
--
ALTER TABLE `classlevels`
 ADD PRIMARY KEY (`classlevel_id`), ADD KEY `classgroup_id` (`classgroup_id`);

--
-- Indexes for table `classrooms`
--
ALTER TABLE `classrooms`
 ADD PRIMARY KEY (`class_id`), ADD KEY `classlevel_id` (`classlevel_id`), ADD KEY `class_status_id` (`class_status_id`);

--
-- Indexes for table `countries`
--
ALTER TABLE `countries`
 ADD PRIMARY KEY (`country_id`);

--
-- Indexes for table `employee_qualifications`
--
ALTER TABLE `employee_qualifications`
 ADD PRIMARY KEY (`employee_qualification_id`);

--
-- Indexes for table `employee_types`
--
ALTER TABLE `employee_types`
 ADD PRIMARY KEY (`employee_type_id`);

--
-- Indexes for table `employees`
--
ALTER TABLE `employees`
 ADD PRIMARY KEY (`employee_id`);

--
-- Indexes for table `exam_details`
--
ALTER TABLE `exam_details`
 ADD PRIMARY KEY (`exam_detail_id`);

--
-- Indexes for table `exams`
--
ALTER TABLE `exams`
 ADD PRIMARY KEY (`exam_id`);

--
-- Indexes for table `grades`
--
ALTER TABLE `grades`
 ADD PRIMARY KEY (`grades_id`);

--
-- Indexes for table `item_bills`
--
ALTER TABLE `item_bills`
 ADD PRIMARY KEY (`item_bill_id`);

--
-- Indexes for table `item_types`
--
ALTER TABLE `item_types`
 ADD PRIMARY KEY (`item_type_id`);

--
-- Indexes for table `item_variables`
--
ALTER TABLE `item_variables`
 ADD PRIMARY KEY (`item_variable_id`);

--
-- Indexes for table `items`
--
ALTER TABLE `items`
 ADD PRIMARY KEY (`item_id`);

--
-- Indexes for table `local_govts`
--
ALTER TABLE `local_govts`
 ADD PRIMARY KEY (`local_govt_id`);

--
-- Indexes for table `master_setups`
--
ALTER TABLE `master_setups`
 ADD PRIMARY KEY (`master_setup_id`);

--
-- Indexes for table `message_recipients`
--
ALTER TABLE `message_recipients`
 ADD PRIMARY KEY (`message_recipient_id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
 ADD PRIMARY KEY (`message_id`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
 ADD PRIMARY KEY (`order_item_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
 ADD PRIMARY KEY (`order_id`);

--
-- Indexes for table `process_items`
--
ALTER TABLE `process_items`
 ADD PRIMARY KEY (`process_item_id`);

--
-- Indexes for table `relationship_types`
--
ALTER TABLE `relationship_types`
 ADD PRIMARY KEY (`relationship_type_id`);

--
-- Indexes for table `salutations`
--
ALTER TABLE `salutations`
 ADD PRIMARY KEY (`salutation_id`);

--
-- Indexes for table `setups`
--
ALTER TABLE `setups`
 ADD PRIMARY KEY (`setup_id`);

--
-- Indexes for table `skill_assessments`
--
ALTER TABLE `skill_assessments`
 ADD PRIMARY KEY (`skill_assessment_id`);

--
-- Indexes for table `skills`
--
ALTER TABLE `skills`
 ADD PRIMARY KEY (`skill_id`);

--
-- Indexes for table `sponsors`
--
ALTER TABLE `sponsors`
 ADD PRIMARY KEY (`sponsor_id`);

--
-- Indexes for table `sponsorship_types`
--
ALTER TABLE `sponsorship_types`
 ADD PRIMARY KEY (`sponsorship_type_id`);

--
-- Indexes for table `spouse_details`
--
ALTER TABLE `spouse_details`
 ADD PRIMARY KEY (`spouse_detail_id`);

--
-- Indexes for table `states`
--
ALTER TABLE `states`
 ADD PRIMARY KEY (`state_id`);

--
-- Indexes for table `status`
--
ALTER TABLE `status`
 ADD PRIMARY KEY (`status_id`);

--
-- Indexes for table `student_status`
--
ALTER TABLE `student_status`
 ADD PRIMARY KEY (`student_status_id`);

--
-- Indexes for table `students`
--
ALTER TABLE `students`
 ADD PRIMARY KEY (`student_id`);

--
-- Indexes for table `students_classes`
--
ALTER TABLE `students_classes`
 ADD PRIMARY KEY (`student_class_id`);

--
-- Indexes for table `subject_classlevels`
--
ALTER TABLE `subject_classlevels`
 ADD PRIMARY KEY (`subject_classlevel_id`);

--
-- Indexes for table `subject_groups`
--
ALTER TABLE `subject_groups`
 ADD PRIMARY KEY (`subject_group_id`);

--
-- Indexes for table `subjects`
--
ALTER TABLE `subjects`
 ADD PRIMARY KEY (`subject_id`);

--
-- Indexes for table `teachers_classes`
--
ALTER TABLE `teachers_classes`
 ADD PRIMARY KEY (`teacher_class_id`);

--
-- Indexes for table `teachers_subjects`
--
ALTER TABLE `teachers_subjects`
 ADD PRIMARY KEY (`teachers_subjects_id`);

--
-- Indexes for table `user_roles`
--
ALTER TABLE `user_roles`
 ADD PRIMARY KEY (`user_role_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
 ADD PRIMARY KEY (`user_id`), ADD KEY `user_role_id` (`user_role_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `academic_terms`
--
ALTER TABLE `academic_terms`
MODIFY `academic_term_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `academic_years`
--
ALTER TABLE `academic_years`
MODIFY `academic_year_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `acos`
--
ALTER TABLE `acos`
MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=144;
--
-- AUTO_INCREMENT for table `aros`
--
ALTER TABLE `aros`
MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `aros_acos`
--
ALTER TABLE `aros_acos`
MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=45;
--
-- AUTO_INCREMENT for table `assessments`
--
ALTER TABLE `assessments`
MODIFY `assessment_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `attends`
--
ALTER TABLE `attends`
MODIFY `attend_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=20;
--
-- AUTO_INCREMENT for table `classgroups`
--
ALTER TABLE `classgroups`
MODIFY `classgroup_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `classlevels`
--
ALTER TABLE `classlevels`
MODIFY `classlevel_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=17;
--
-- AUTO_INCREMENT for table `classrooms`
--
ALTER TABLE `classrooms`
MODIFY `class_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=113;
--
-- AUTO_INCREMENT for table `countries`
--
ALTER TABLE `countries`
MODIFY `country_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=234;
--
-- AUTO_INCREMENT for table `employee_qualifications`
--
ALTER TABLE `employee_qualifications`
MODIFY `employee_qualification_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=13;
--
-- AUTO_INCREMENT for table `employee_types`
--
ALTER TABLE `employee_types`
MODIFY `employee_type_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `employees`
--
ALTER TABLE `employees`
MODIFY `employee_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=21;
--
-- AUTO_INCREMENT for table `exam_details`
--
ALTER TABLE `exam_details`
MODIFY `exam_detail_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=72;
--
-- AUTO_INCREMENT for table `exams`
--
ALTER TABLE `exams`
MODIFY `exam_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=24;
--
-- AUTO_INCREMENT for table `grades`
--
ALTER TABLE `grades`
MODIFY `grades_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=21;
--
-- AUTO_INCREMENT for table `item_bills`
--
ALTER TABLE `item_bills`
MODIFY `item_bill_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=16;
--
-- AUTO_INCREMENT for table `item_types`
--
ALTER TABLE `item_types`
MODIFY `item_type_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `item_variables`
--
ALTER TABLE `item_variables`
MODIFY `item_variable_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=6;
--
-- AUTO_INCREMENT for table `items`
--
ALTER TABLE `items`
MODIFY `item_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `local_govts`
--
ALTER TABLE `local_govts`
MODIFY `local_govt_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=781;
--
-- AUTO_INCREMENT for table `master_setups`
--
ALTER TABLE `master_setups`
MODIFY `master_setup_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `message_recipients`
--
ALTER TABLE `message_recipients`
MODIFY `message_recipient_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
MODIFY `message_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=17;
--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
MODIFY `order_item_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=83;
--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=54;
--
-- AUTO_INCREMENT for table `process_items`
--
ALTER TABLE `process_items`
MODIFY `process_item_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `relationship_types`
--
ALTER TABLE `relationship_types`
MODIFY `relationship_type_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=10;
--
-- AUTO_INCREMENT for table `salutations`
--
ALTER TABLE `salutations`
MODIFY `salutation_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=12;
--
-- AUTO_INCREMENT for table `setups`
--
ALTER TABLE `setups`
MODIFY `setup_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `skill_assessments`
--
ALTER TABLE `skill_assessments`
MODIFY `skill_assessment_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=52;
--
-- AUTO_INCREMENT for table `skills`
--
ALTER TABLE `skills`
MODIFY `skill_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=18;
--
-- AUTO_INCREMENT for table `sponsors`
--
ALTER TABLE `sponsors`
MODIFY `sponsor_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=34;
--
-- AUTO_INCREMENT for table `sponsorship_types`
--
ALTER TABLE `sponsorship_types`
MODIFY `sponsorship_type_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `spouse_details`
--
ALTER TABLE `spouse_details`
MODIFY `spouse_detail_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `states`
--
ALTER TABLE `states`
MODIFY `state_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=38;
--
-- AUTO_INCREMENT for table `status`
--
ALTER TABLE `status`
MODIFY `status_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `student_status`
--
ALTER TABLE `student_status`
MODIFY `student_status_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=6;
--
-- AUTO_INCREMENT for table `students`
--
ALTER TABLE `students`
MODIFY `student_id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=64;
--
-- AUTO_INCREMENT for table `students_classes`
--
ALTER TABLE `students_classes`
MODIFY `student_class_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=59;
--
-- AUTO_INCREMENT for table `subject_classlevels`
--
ALTER TABLE `subject_classlevels`
MODIFY `subject_classlevel_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=38;
--
-- AUTO_INCREMENT for table `subject_groups`
--
ALTER TABLE `subject_groups`
MODIFY `subject_group_id` int(3) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `subjects`
--
ALTER TABLE `subjects`
MODIFY `subject_id` int(3) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=27;
--
-- AUTO_INCREMENT for table `teachers_classes`
--
ALTER TABLE `teachers_classes`
MODIFY `teacher_class_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=10;
--
-- AUTO_INCREMENT for table `teachers_subjects`
--
ALTER TABLE `teachers_subjects`
MODIFY `teachers_subjects_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=25;
--
-- AUTO_INCREMENT for table `user_roles`
--
ALTER TABLE `user_roles`
MODIFY `user_role_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
MODIFY `user_id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=6;
--
-- Constraints for dumped tables
--

--
-- Constraints for table `academic_terms`
--
ALTER TABLE `academic_terms`
ADD CONSTRAINT `academic_year_id` FOREIGN KEY (`academic_year_id`) REFERENCES `academic_years` (`academic_year_id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Constraints for table `classlevels`
--
ALTER TABLE `classlevels`
ADD CONSTRAINT `classgroup_id` FOREIGN KEY (`classgroup_id`) REFERENCES `classgroups` (`classgroup_id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Constraints for table `classrooms`
--
ALTER TABLE `classrooms`
ADD CONSTRAINT `classlevel_id` FOREIGN KEY (`classlevel_id`) REFERENCES `classlevels` (`classlevel_id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
