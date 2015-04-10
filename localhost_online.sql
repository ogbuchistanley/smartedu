-- phpMyAdmin SQL Dump
-- version 4.2.7.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Apr 10, 2015 at 02:47 PM
-- Server version: 5.6.20
-- PHP Version: 5.5.15

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `smartedu_online`
--

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
		class_size int, PRIMARY KEY (row_id)
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
								UPDATE AnnualClassPositionResultTable SET class_annual_position=@Position, class_size=@ClassSize
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


	IF @ClassID IS NULL OR @ClassID = -1 THEN
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
						subject_classlevels ON exams.subject_classlevel_id = subject_classlevels.subject_classlevel_id INNER JOIN 
                        classlevels ON subject_classlevels.classlevel_id = classlevels.classlevel_id INNER JOIN
                        classgroups ON classlevels.classgroup_id = classgroups.classgroup_id
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_processExams`(IN `TermID` INT)
BEGIN 
	Block0: BEGIN								
		-- Delete the exams details record for that term if its has not been marked already
		DELETE FROM exam_details WHERE exam_id IN 
		(SELECT exam_id FROM exam_subjectviews WHERE academic_term_id=TermID AND exammarked_status_id=2);
		
		-- Delete the exams record for that term if its has not been marked already
		DELETE FROM exams WHERE exammarked_status_id=2 AND subject_classlevel_id IN 
		(SELECT subject_classlevel_id FROM subject_classlevels WHERE academic_term_id=TermID);
	END Block0;
    
    Block1: BEGIN	
		-- Insert into exams table with all the subjects that has assigned to a class room with students offering them
		-- also skip those records that exist already to avoid duplicates in terms of class_id and subject_classlevel_id
		INSERT INTO exams(class_id, subject_classlevel_id)
		SELECT a.class_id, a.subject_classlevel_id FROM classroom_subjectregisterviews a 
		WHERE a.academic_term_id=TermID AND a.class_id NOT IN 
		(SELECT class_id FROM exams b WHERE academic_term_id=TermID AND b.subject_classlevel_id = a.subject_classlevel_id);
		
        -- Update the exam setup status_id = 1
        UPDATE subject_classlevels set examstatus_id=1;
    END Block1;
    
    -- insert into exams details the students offering such subjects in the class room using the exams assigned
    -- cursor block for inserting exam details from exams and subject_students_registers
	Block2: BEGIN								
		DECLARE done1 BOOLEAN DEFAULT FALSE;
		DECLARE ExamID, ClassID, SubjectClasslevelID, ExamMarkStatusID INT;
		-- DECLARE cur1 CURSOR FOR SELECT a.exam_id, a.class_id, a.subject_classlevel_id, a.exammarked_status_id
        DECLARE cur1 CURSOR FOR SELECT a.*
		FROM exams a INNER JOIN subject_classlevels b ON a.subject_classlevel_id=b.subject_classlevel_id 
        WHERE b.academic_term_id=TermID;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;
	
		#Open The Cursor For Iterating Through The Recordset cur1
		OPEN cur1;
			REPEAT
			FETCH cur1 INTO ExamID, ClassID, SubjectClasslevelID, ExamMarkStatusID;
				IF NOT done1 THEN	
					BEGIN
						IF ExamMarkStatusID = 2 THEN
							BEGIN
								# Insert into the details table all the students that registered the subject
								INSERT INTO exam_details(exam_id, student_id)
								SELECT	ExamID, student_id
								FROM	subject_students_registers
								WHERE 	class_id=ClassID AND subject_classlevel_id=SubjectClasslevelID;
							END;
						ELSE
                        	BEGIN
								# Insert into the details table the students that was just added to offer the subject
								INSERT INTO exam_details(exam_id, student_id)
								SELECT	ExamID, student_id
								FROM 	subject_students_registers
								WHERE 	class_id=ClassID AND subject_classlevel_id=SubjectClasslevelID AND student_id NOT IN
                                (SELECT student_id FROM exam_details WHERE exam_id=ExamID);
                                
                                # remove the students that was just removed from the list of students to offer the subject
                                DELETE FROM exam_details WHERE exam_id=ExamID AND student_id NOT IN 
								(
									SELECT student_id FROM subject_students_registers 
									WHERE class_id=ClassID AND subject_classlevel_id=SubjectClasslevelID
                                );
							END;
						END IF;
					END;
				END IF;
			UNTIL done1 END REPEAT;
		CLOSE cur1;								
	END Block2;
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
    SET @Average = 0;
	SET @Count = 0;
	
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
		class_size int,
        class_average float
        
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
								VALUES(StudentID, StudentName, ClassID, ClassName, TermID, TermName, StudentSumTotal, ExamPerfectScore, @Position, @ClassSize, @Average);
							END;
							-- Get the current student total score and set it the variable for the next comparism 
							SET @TempStudentScore = @StudentSumTotal;	
                            
                            -- Get the average of the students scores
                            SET @Average = @Average + StudentSumTotal;
                            -- Update Count
                            SET @Count = @Count + 1;
                            -- Update the average scores of the students
                            UPDATE TerminalClassPositionResultTable SET class_average = (@Average / @Count);
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
						IF ci > 0 OR ci IS NOT NULL THEN
							-- Insert into the resultant table that will display the results
							BEGIN
								INSERT INTO SubjectClasslevelResultTable VALUES(cn, sn, si, ci, cli, scli, cl, esi, es, ati, atn, ayi, ayn);			
							END;
						ELSE
							BEGIN
								INSERT INTO SubjectClasslevelResultTable(class_name, subject_name,subject_id, class_id, classlevel_id, subject_classlevel_id,
									classlevel, examstatus_id, exam_status, academic_term_id, academic_term, academic_year_id, academic_year) 
								SELECT a.class_name, sn, si, a.class_id, cli, scli, cl, esi, es, ati, atn, ayi, ayn
                                FROM classroom_subjectregisterviews a
                                WHERE a.subject_classlevel_id=scli AND a.academic_term_id=ati;
                                
                                -- SELECT classrooms.class_name, sn, si, classrooms.class_id, cli, scli, cl, esi, es, ati, atn, ayi, ayn
								-- FROM   classrooms INNER JOIN classlevels ON classrooms.classlevel_id = classlevels.classlevel_id
								-- WHERE classrooms.classlevel_id = cli;		
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
  `exam_status_id` int(11) NOT NULL DEFAULT '2',
  `exam_setup_by` int(11) DEFAULT '0',
  `exam_setup_date` datetime DEFAULT NULL,
  `term_begins` date DEFAULT NULL,
  `term_ends` date DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=4 ;

--
-- Dumping data for table `academic_terms`
--

INSERT INTO `academic_terms` (`academic_term_id`, `academic_term`, `academic_year_id`, `term_status_id`, `term_type_id`, `exam_status_id`, `exam_setup_by`, `exam_setup_date`, `term_begins`, `term_ends`, `created_at`, `updated_at`) VALUES
(1, '2014/2015 Second Term', 1, 1, 2, 1, 1, '2015-04-08 11:04:46', NULL, NULL, '2015-04-08 11:27:46', '2015-04-08 10:27:46'),
(2, '2014/2015 Third Term', 1, 2, 3, 2, 0, '0000-00-00 00:00:00', '2015-04-20', '2015-07-31', NULL, '2015-04-07 13:54:56'),
(3, '2015/2016 First Term', 2, 2, 1, 2, 0, '0000-00-00 00:00:00', NULL, NULL, NULL, '2015-04-07 13:43:53');

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
(1, '2014/2015', 1, '2015-03-19 12:36:24', '2015-03-19 11:36:24'),
(2, '2015/2016', 2, NULL, '2015-04-07 13:39:25');

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=157 ;

--
-- Dumping data for table `acos`
--

INSERT INTO `acos` (`id`, `parent_id`, `model`, `foreign_key`, `alias`, `lft`, `rght`) VALUES
(1, NULL, NULL, NULL, 'controllers', 1, 312),
(2, 1, NULL, NULL, 'AcademicTermsController', 2, 5),
(3, 2, NULL, NULL, 'ajax_get_terms', 3, 4),
(4, 1, NULL, NULL, 'AcademicYearsController', 6, 7),
(5, 1, NULL, NULL, 'AppController', 8, 9),
(6, 1, NULL, NULL, 'AssessmentsController', 10, 23),
(7, 6, NULL, NULL, 'index', 11, 12),
(8, 6, NULL, NULL, 'view', 13, 14),
(9, 6, NULL, NULL, 'remark', 15, 16),
(10, 6, NULL, NULL, 'saveRemark', 17, 18),
(11, 6, NULL, NULL, 'assess', 19, 20),
(12, 6, NULL, NULL, 'edit', 21, 22),
(13, 1, NULL, NULL, 'AttendsController', 24, 45),
(14, 13, NULL, NULL, 'index', 25, 26),
(15, 13, NULL, NULL, 'search_students', 27, 28),
(16, 13, NULL, NULL, 'take_attend', 29, 30),
(17, 13, NULL, NULL, 'validateIfExist', 31, 32),
(18, 13, NULL, NULL, 'search_attend', 33, 34),
(19, 13, NULL, NULL, 'view', 35, 36),
(20, 13, NULL, NULL, 'edit', 37, 38),
(21, 13, NULL, NULL, 'search_summary', 39, 40),
(22, 13, NULL, NULL, 'summary', 41, 42),
(23, 13, NULL, NULL, 'details', 43, 44),
(24, 1, NULL, NULL, 'ClassroomsController', 46, 59),
(25, 24, NULL, NULL, 'ajax_get_classes', 47, 48),
(26, 24, NULL, NULL, 'index', 49, 50),
(27, 24, NULL, NULL, 'myclass', 51, 52),
(28, 24, NULL, NULL, 'search_classes', 53, 54),
(29, 24, NULL, NULL, 'assign_head_tutor', 55, 56),
(30, 24, NULL, NULL, 'view', 57, 58),
(31, 1, NULL, NULL, 'DashboardController', 60, 77),
(32, 31, NULL, NULL, 'index', 61, 62),
(33, 31, NULL, NULL, 'tutor', 63, 64),
(34, 31, NULL, NULL, 'studentGender', 65, 66),
(35, 31, NULL, NULL, 'studentStauts', 67, 68),
(36, 31, NULL, NULL, 'studentPaymentStatus', 69, 70),
(37, 31, NULL, NULL, 'studentClasslevel', 71, 72),
(38, 31, NULL, NULL, 'classHeadTutor', 73, 74),
(39, 31, NULL, NULL, 'subjectHeadTutor', 75, 76),
(40, 1, NULL, NULL, 'EmployeesController', 78, 95),
(41, 40, NULL, NULL, 'autoComplete', 79, 80),
(42, 40, NULL, NULL, 'validate_form', 81, 82),
(43, 40, NULL, NULL, 'index', 83, 84),
(44, 40, NULL, NULL, 'register', 85, 86),
(45, 40, NULL, NULL, 'view', 87, 88),
(46, 40, NULL, NULL, 'adjust', 89, 90),
(47, 40, NULL, NULL, 'delete', 91, 92),
(48, 40, NULL, NULL, 'statusUpdate', 93, 94),
(49, 1, NULL, NULL, 'ExamsController', 96, 131),
(50, 49, NULL, NULL, 'index', 97, 98),
(51, 49, NULL, NULL, 'setup_validate', 99, 100),
(52, 49, NULL, NULL, 'setup_exam', 101, 102),
(53, 49, NULL, NULL, 'get_exam_setup', 103, 104),
(54, 49, NULL, NULL, 'search_subjects_assigned', 105, 106),
(55, 49, NULL, NULL, 'search_subjects_examSetup', 107, 108),
(56, 49, NULL, NULL, 'enter_scores', 109, 110),
(57, 49, NULL, NULL, 'view_scores', 111, 112),
(58, 49, NULL, NULL, 'search_student_classlevel', 113, 114),
(59, 49, NULL, NULL, 'term_scorestd', 115, 116),
(60, 49, NULL, NULL, 'term_scorecls', 117, 118),
(61, 49, NULL, NULL, 'annual_scorestd', 119, 120),
(62, 49, NULL, NULL, 'annual_scorecls', 121, 122),
(63, 49, NULL, NULL, 'print_result', 123, 124),
(64, 49, NULL, NULL, 'chart', 125, 126),
(65, 49, NULL, NULL, 'chart_analysis', 127, 128),
(66, 49, NULL, NULL, 'chart_anal', 129, 130),
(67, 1, NULL, NULL, 'HomeController', 132, 149),
(68, 67, NULL, NULL, 'index', 133, 134),
(69, 67, NULL, NULL, 'setup', 135, 136),
(70, 67, NULL, NULL, 'students', 137, 138),
(71, 67, NULL, NULL, 'exam', 139, 140),
(72, 67, NULL, NULL, 'search_student', 141, 142),
(73, 67, NULL, NULL, 'term_scorestd', 143, 144),
(74, 67, NULL, NULL, 'annual_scorestd', 145, 146),
(75, 67, NULL, NULL, 'view_stdfees', 147, 148),
(76, 1, NULL, NULL, 'ItemsController', 150, 169),
(77, 76, NULL, NULL, 'index', 151, 152),
(78, 76, NULL, NULL, 'summary', 153, 154),
(79, 76, NULL, NULL, 'payment_status', 155, 156),
(80, 76, NULL, NULL, 'validateIfExist', 157, 158),
(81, 76, NULL, NULL, 'process_fees', 159, 160),
(82, 76, NULL, NULL, 'bill_students', 161, 162),
(83, 76, NULL, NULL, 'view_stdfees', 163, 164),
(84, 76, NULL, NULL, 'view_clsfees', 165, 166),
(85, 76, NULL, NULL, 'statusUpdate', 167, 168),
(86, 1, NULL, NULL, 'LocalGovtsController', 170, 173),
(87, 86, NULL, NULL, 'ajax_get_local_govt', 171, 172),
(88, 1, NULL, NULL, 'MessagesController', 174, 189),
(89, 88, NULL, NULL, 'index', 175, 176),
(90, 88, NULL, NULL, 'recipient', 177, 178),
(91, 88, NULL, NULL, 'delete_recipient', 179, 180),
(92, 88, NULL, NULL, 'send', 181, 182),
(93, 88, NULL, NULL, 'sendOne', 183, 184),
(94, 88, NULL, NULL, 'search_student_classlevel', 185, 186),
(95, 88, NULL, NULL, 'encrypt', 187, 188),
(96, 1, NULL, NULL, 'RecordsController', 190, 213),
(97, 96, NULL, NULL, 'deleteIDs', 191, 192),
(98, 96, NULL, NULL, 'academic_year', 193, 194),
(99, 96, NULL, NULL, 'index', 195, 196),
(100, 96, NULL, NULL, 'class_group', 197, 198),
(101, 96, NULL, NULL, 'class_level', 199, 200),
(102, 96, NULL, NULL, 'class_room', 201, 202),
(103, 96, NULL, NULL, 'subject_group', 203, 204),
(104, 96, NULL, NULL, 'subject', 205, 206),
(105, 96, NULL, NULL, 'grade', 207, 208),
(106, 96, NULL, NULL, 'item', 209, 210),
(107, 96, NULL, NULL, 'item_bill', 211, 212),
(108, 1, NULL, NULL, 'SetupsController', 214, 217),
(109, 108, NULL, NULL, 'setup', 215, 216),
(110, 1, NULL, NULL, 'SponsorsController', 218, 233),
(111, 110, NULL, NULL, 'autoComplete', 219, 220),
(112, 110, NULL, NULL, 'validate_form', 221, 222),
(113, 110, NULL, NULL, 'index', 223, 224),
(114, 110, NULL, NULL, 'register', 225, 226),
(115, 110, NULL, NULL, 'view', 227, 228),
(116, 110, NULL, NULL, 'adjust', 229, 230),
(117, 110, NULL, NULL, 'delete', 231, 232),
(118, 1, NULL, NULL, 'StudentsClassesController', 234, 241),
(119, 118, NULL, NULL, 'assign', 235, 236),
(120, 118, NULL, NULL, 'search', 237, 238),
(121, 118, NULL, NULL, 'search_all', 239, 240),
(122, 1, NULL, NULL, 'StudentsController', 242, 257),
(123, 122, NULL, NULL, 'validate_form', 243, 244),
(124, 122, NULL, NULL, 'index', 245, 246),
(125, 122, NULL, NULL, 'view', 247, 248),
(126, 122, NULL, NULL, 'register', 249, 250),
(127, 122, NULL, NULL, 'adjust', 251, 252),
(128, 122, NULL, NULL, 'delete', 253, 254),
(129, 122, NULL, NULL, 'statusUpdate', 255, 256),
(130, 1, NULL, NULL, 'SubjectsController', 258, 293),
(131, 130, NULL, NULL, 'ajax_get_subjects', 259, 260),
(132, 130, NULL, NULL, 'add2class', 261, 262),
(133, 130, NULL, NULL, 'assign', 263, 264),
(134, 130, NULL, NULL, 'validateIfExist', 265, 266),
(135, 130, NULL, NULL, 'search_all', 267, 268),
(136, 130, NULL, NULL, 'assign_tutor', 269, 270),
(137, 130, NULL, NULL, 'search_assigned', 271, 272),
(138, 130, NULL, NULL, 'modify_assign', 273, 274),
(139, 130, NULL, NULL, 'delete_assign', 275, 276),
(140, 130, NULL, NULL, 'search_students', 277, 278),
(141, 130, NULL, NULL, 'updateStudentsSubjects', 279, 280),
(142, 130, NULL, NULL, 'index', 281, 282),
(143, 130, NULL, NULL, 'search_assigned2Staff', 283, 284),
(144, 130, NULL, NULL, 'search_students_subjects', 285, 286),
(145, 130, NULL, NULL, 'updateStudentsStaffSubjects', 287, 288),
(146, 130, NULL, NULL, 'search_subject', 289, 290),
(147, 130, NULL, NULL, 'view', 291, 292),
(148, 1, NULL, NULL, 'UsersController', 294, 311),
(149, 148, NULL, NULL, 'login', 295, 296),
(150, 148, NULL, NULL, 'logout', 297, 298),
(151, 148, NULL, NULL, 'index', 299, 300),
(152, 148, NULL, NULL, 'register', 301, 302),
(153, 148, NULL, NULL, 'forget_password', 303, 304),
(154, 148, NULL, NULL, 'adjust', 305, 306),
(155, 148, NULL, NULL, 'change', 307, 308),
(156, 148, NULL, NULL, 'statusUpdate', 309, 310);

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
(1, NULL, NULL, NULL, 'EXPIRED_USERS', 1, 2),
(2, NULL, NULL, NULL, 'PAR_USERS', 3, 4),
(3, NULL, NULL, NULL, 'STF_USERS', 5, 6),
(4, NULL, NULL, NULL, 'ICT_USERS', 7, 8),
(5, NULL, NULL, NULL, 'APP_USERS', 9, 10),
(6, NULL, NULL, NULL, 'ADM_USERS', 11, 12);

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=49 ;

--
-- Dumping data for table `aros_acos`
--

INSERT INTO `aros_acos` (`id`, `aro_id`, `aco_id`, `_create`, `_read`, `_update`, `_delete`) VALUES
(1, 1, 1, '-1', '-1', '-1', '-1'),
(2, 2, 1, '-1', '-1', '-1', '-1'),
(3, 2, 67, '1', '1', '1', '1'),
(4, 2, 125, '1', '1', '1', '1'),
(5, 2, 115, '1', '1', '1', '1'),
(6, 2, 116, '0', '0', '1', '0'),
(7, 2, 113, '-1', '-1', '-1', '-1'),
(8, 3, 1, '-1', '-1', '-1', '-1'),
(9, 3, 31, '1', '1', '1', '1'),
(10, 3, 49, '1', '1', '1', '1'),
(11, 3, 130, '1', '1', '1', '1'),
(12, 3, 132, '-1', '-1', '-1', '-1'),
(13, 3, 52, '-1', '-1', '-1', '-1'),
(14, 3, 13, '1', '1', '1', '1'),
(15, 3, 125, '1', '1', '1', '1'),
(16, 3, 27, '1', '1', '1', '1'),
(17, 3, 30, '1', '1', '1', '1'),
(18, 3, 46, '0', '0', '1', '0'),
(19, 4, 1, '-1', '-1', '-1', '-1'),
(20, 4, 31, '1', '1', '1', '1'),
(21, 4, 96, '1', '1', '1', '1'),
(22, 4, 13, '1', '1', '1', '1'),
(23, 4, 49, '1', '1', '1', '1'),
(24, 4, 52, '-1', '-1', '-1', '-1'),
(25, 4, 24, '1', '1', '1', '1'),
(26, 4, 122, '1', '1', '1', '1'),
(27, 4, 124, '1', '1', '1', '1'),
(28, 4, 125, '1', '1', '1', '1'),
(29, 4, 126, '1', '0', '0', '0'),
(30, 4, 127, '0', '0', '1', '0'),
(31, 4, 128, '0', '0', '0', '-1'),
(32, 4, 110, '1', '1', '1', '1'),
(33, 4, 113, '1', '1', '1', '1'),
(34, 4, 115, '1', '1', '1', '1'),
(35, 4, 114, '1', '0', '0', '0'),
(36, 4, 116, '0', '0', '1', '0'),
(37, 4, 117, '0', '0', '0', '-1'),
(38, 4, 40, '1', '1', '1', '1'),
(39, 4, 43, '1', '1', '1', '1'),
(40, 4, 44, '1', '0', '0', '0'),
(41, 4, 46, '0', '0', '1', '0'),
(42, 4, 47, '0', '0', '0', '-1'),
(43, 4, 130, '1', '1', '1', '1'),
(44, 4, 132, '1', '1', '1', '1'),
(45, 4, 76, '1', '1', '1', '1'),
(46, 4, 81, '-1', '-1', '-1', '-1'),
(47, 6, 1, '1', '1', '1', '1'),
(48, 6, 67, '-1', '-1', '-1', '-1');

-- --------------------------------------------------------

--
-- Table structure for table `assessments`
--

CREATE TABLE IF NOT EXISTS `assessments` (
`assessment_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `academic_term_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `attend_details`
--

CREATE TABLE IF NOT EXISTS `attend_details` (
  `student_id` int(11) DEFAULT NULL,
  `attend_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

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
,`head_tutor` varchar(201)
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
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `classgroups`
--

CREATE TABLE IF NOT EXISTS `classgroups` (
`classgroup_id` int(11) unsigned NOT NULL,
  `classgroup` varchar(50) DEFAULT NULL,
  `weightageCA1` int(10) unsigned DEFAULT '0',
  `weightageCA2` int(10) unsigned DEFAULT '0',
  `weightageExam` int(10) unsigned DEFAULT '0'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=3 ;

--
-- Dumping data for table `classgroups`
--

INSERT INTO `classgroups` (`classgroup_id`, `classgroup`, `weightageCA1`, `weightageCA2`, `weightageExam`) VALUES
(1, 'Junior Secondary School', 15, 15, 70),
(2, 'Senior Secondary School', 15, 15, 70);

-- --------------------------------------------------------

--
-- Table structure for table `classlevels`
--

CREATE TABLE IF NOT EXISTS `classlevels` (
`classlevel_id` int(11) NOT NULL,
  `classlevel` varchar(50) DEFAULT NULL,
  `classgroup_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

--
-- Dumping data for table `classlevels`
--

INSERT INTO `classlevels` (`classlevel_id`, `classlevel`, `classgroup_id`) VALUES
(1, 'JS 1', 1),
(2, 'JS 2', 1),
(3, 'JS 3', 1),
(4, 'SS 1', 2),
(5, 'SS 2', 2),
(6, 'SS 3', 2);

-- --------------------------------------------------------

--
-- Stand-in structure for view `classroom_subjectregisterviews`
--
CREATE TABLE IF NOT EXISTS `classroom_subjectregisterviews` (
`student_id` int(11)
,`class_id` int(11)
,`subject_classlevel_id` int(11)
,`subject_id` int(11)
,`academic_term_id` int(11)
,`examstatus_id` int(11)
,`classlevel_id` int(11)
,`class_name` varchar(50)
);
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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=31 ;

--
-- Dumping data for table `classrooms`
--

INSERT INTO `classrooms` (`class_id`, `class_name`, `classlevel_id`, `class_size`, `class_status_id`) VALUES
(1, 'JS 1 Yellow Day', 1, NULL, 1),
(2, 'JS 1 White Boys', 1, NULL, 1),
(4, 'JS 1 White Girls', 1, NULL, 1),
(5, 'JS 1 White Day', 1, NULL, 1),
(7, 'JS 2 White Boys', 2, NULL, 1),
(9, 'JS 2 White Girls', 2, NULL, 1),
(10, 'JS 2 White Day', 2, NULL, 1),
(11, 'JS 3 Yellow Boys', 3, NULL, 1),
(12, 'JS 3 White Boys', 3, NULL, 1),
(13, 'JS 3 Yellow Girls', 3, NULL, 1),
(14, 'JS 3 White Girls', 3, NULL, 1),
(15, 'JS 3 White Day', 3, NULL, 1),
(17, 'SS 1 White Boys', 4, NULL, 1),
(19, 'SS 1 White Girls', 4, NULL, 1),
(20, 'SS 1 White Day', 4, NULL, 1),
(22, 'SS 2 White Boys', 5, NULL, 1),
(24, 'SS 2 White Girls', 5, NULL, 1),
(25, 'SS 2 White Day', 5, NULL, 1),
(27, 'SS 3 White Boys', 6, NULL, 1),
(29, 'SS 3 White Girls', 6, NULL, 1),
(30, 'SS 3 White Day', 6, NULL, 1);

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=3 ;

--
-- Dumping data for table `employee_qualifications`
--

INSERT INTO `employee_qualifications` (`employee_qualification_id`, `employee_id`, `institution`, `qualification`, `date_from`, `date_to`, `qualification_date`) VALUES
(1, 1, '', '', NULL, NULL, NULL),
(2, 1, '', '', NULL, NULL, NULL);

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
  `other_name` varchar(100) DEFAULT NULL,
  `first_name` varchar(100) DEFAULT NULL,
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
  `local_govt_id` int(11) unsigned DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `next_ofkin_name` varchar(70) DEFAULT NULL,
  `next_ofkin_number` varchar(15) DEFAULT NULL,
  `next_ofkin_relate` varchar(30) DEFAULT NULL,
  `form_of_identity` varchar(100) DEFAULT NULL,
  `identity_no` varchar(30) DEFAULT NULL,
  `identity_expiry_date` date DEFAULT NULL,
  `status_id` int(2) NOT NULL DEFAULT '1',
  `created_by` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=68 ;

--
-- Dumping data for table `employees`
--

INSERT INTO `employees` (`employee_id`, `employee_no`, `salutation_id`, `other_name`, `first_name`, `gender`, `birth_date`, `image_url`, `contact_address`, `employee_type_id`, `mobile_number1`, `mobile_number2`, `marital_status`, `country_id`, `state_id`, `local_govt_id`, `email`, `next_ofkin_name`, `next_ofkin_number`, `next_ofkin_relate`, `form_of_identity`, `identity_no`, `identity_expiry_date`, `status_id`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'STF0001', 1, 'Kudaisi', 'Dotun', 'Male', '2015-03-03', 'employees/1.png', 'iofdi', NULL, '08052139529', '', 'Single', 140, 5, NULL, 'dotman2kx@gmail.com', 'djj', '08019189298', 'jdfhjdfh', '', '', '1970-01-01', 1, 1, '2015-03-19 02:16:59', '2015-03-24 16:05:02'),
(3, 'STF0003', 1, 'J.', 'Abikoye', NULL, NULL, NULL, NULL, NULL, '07035376722', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:40:35', '2015-03-21 10:03:50'),
(4, 'STF0004', 1, 'M.', 'ADEGOKE', NULL, NULL, NULL, NULL, NULL, '07033895470', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:42:34', '2015-03-21 13:08:24'),
(5, 'STF0005', 1, 'B.', 'ADEYEMI', NULL, NULL, NULL, NULL, NULL, '08068891010', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:47:32', '2015-03-21 13:03:47'),
(6, 'STF0006', 1, 'S.', 'ADISA', NULL, NULL, NULL, NULL, NULL, '08062915800', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:48:42', '2015-03-21 13:03:05'),
(7, 'STF0007', 1, 'A.', 'AIGBOMIAN', NULL, NULL, NULL, NULL, NULL, '07062371754', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:49:44', '2015-03-21 13:02:06'),
(8, 'STF0008', 1, 'G.', 'AJAYI', NULL, NULL, NULL, NULL, NULL, '08060132925', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:53:19', '2015-03-21 13:01:37'),
(9, 'STF0009', 1, 'B.', 'AKINROLABU', NULL, NULL, NULL, NULL, NULL, '08068578087', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:57:44', '2015-03-21 13:00:42'),
(10, 'STF0010', 1, 'D.', 'AKINYEMI', NULL, NULL, NULL, NULL, NULL, '08034497060', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:58:39', '2015-03-21 12:57:44'),
(11, 'STF0011', 4, 'Z.', 'ALIU', NULL, NULL, NULL, NULL, NULL, '08033426503', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:59:28', '2015-03-21 12:55:51'),
(12, 'STF0012', 1, 'A.', 'ANJORIN', NULL, NULL, NULL, NULL, NULL, '08130113255', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:00:59', '2015-03-21 12:54:52'),
(13, 'STF0013', 1, 'O.', 'ARAOYE', NULL, NULL, NULL, NULL, NULL, '08028274106', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:02:00', '2015-03-21 12:53:50'),
(14, 'STF0014', 3, 'A.', 'AWOGBADE', NULL, NULL, NULL, NULL, NULL, '07064818193', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:03:50', '2015-03-21 12:53:17'),
(15, 'STF0015', 4, 'ADERONKE', 'AYEGBUSI', NULL, NULL, NULL, NULL, NULL, '08033877116', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:05:29', '2015-03-21 12:51:24'),
(16, 'STF0016', 4, 'B.', 'AZEEZ', NULL, NULL, NULL, NULL, NULL, '08063533814', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:06:03', '2015-03-21 12:50:48'),
(17, 'STF0017', 4, 'D.', 'AZIAKA', NULL, NULL, NULL, NULL, NULL, '08061697111', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:07:31', '2015-03-21 12:46:34'),
(18, 'STF0018', 4, 'A.', 'BABALOLA', NULL, NULL, NULL, NULL, NULL, '07031233376', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:08:50', '2015-03-21 12:41:48'),
(19, 'STF0019', 4, 'F.', 'BABATOPE', NULL, NULL, NULL, NULL, NULL, '08023629883', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:12:59', '2015-03-21 12:42:21'),
(20, 'STF0020', 4, '.', 'BADERIN', NULL, NULL, NULL, NULL, NULL, '08027282096', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:14:15', '2015-03-21 12:29:19'),
(21, 'STF0021', 1, 'INCREASE ', 'BETIKU', NULL, NULL, NULL, NULL, NULL, '08035714860', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:14:58', '2015-03-21 12:25:18'),
(22, 'STF0022', 1, 'B.', 'DADA', NULL, NULL, NULL, NULL, NULL, '08023979489', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:17:57', '2015-03-21 12:23:51'),
(23, 'STF0023', 4, 'M.', 'EKPUH', NULL, NULL, NULL, NULL, NULL, '08104942760', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:36:44', '2015-03-21 12:21:37'),
(24, 'STF0024', 1, 'E.', 'EKUNBOYEJO', NULL, NULL, NULL, NULL, NULL, '08038321559', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:37:49', '2015-03-21 12:11:50'),
(25, 'STF0025', 1, 'L.', 'EWERE', NULL, NULL, NULL, NULL, NULL, '08160535011', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:39:13', '2015-03-21 12:08:48'),
(26, 'STF0026', 1, 'E. ', 'FAKOLUJO', NULL, NULL, NULL, NULL, NULL, '07057546505', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:39:46', '2015-03-21 11:54:01'),
(27, 'STF0027', 1, 'J.', 'FAMAKINWA', NULL, NULL, NULL, NULL, NULL, '07067834982', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:46:36', '2015-03-21 11:41:46'),
(28, 'STF0028', 1, 'ABIODUN', 'GBADAMOSI', NULL, NULL, NULL, NULL, NULL, '08027524466', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:50:51', '2015-03-21 11:37:09'),
(29, 'STF0029', 1, 'M.', 'IBITAYO', NULL, NULL, NULL, NULL, NULL, '08038330145', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:53:51', '2015-03-21 11:31:42'),
(30, 'STF0030', 3, 'N.', 'IKEME', NULL, NULL, NULL, NULL, NULL, '08137895592', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:57:25', '2015-03-21 11:28:57'),
(32, 'STF0032', 4, 'F.', 'JOSEPH', NULL, NULL, NULL, NULL, NULL, '07060828677', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 08:03:17', '2015-03-21 11:24:48'),
(33, 'STF0033', 1, 'L.', 'KOLORUKO', NULL, NULL, NULL, NULL, NULL, '08064797801', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 08:08:36', '2015-03-21 11:22:18'),
(34, 'STF0034', 1, 'A.', 'LIADI', NULL, NULL, NULL, NULL, NULL, '08062601861', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 08:10:38', '2015-03-21 11:19:14'),
(35, 'STF0035', 1, 'OLANREWAJU', 'MEMUD', NULL, NULL, NULL, NULL, NULL, '08053603925', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 08:11:09', '2015-03-21 11:08:32'),
(36, 'STF0036', 1, 'T.', 'MUDASIRU', NULL, NULL, NULL, NULL, NULL, '08060933502', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 08:15:50', '2015-03-21 11:05:51'),
(38, 'STF0038', 3, 'F.', 'NOAH', NULL, NULL, NULL, NULL, NULL, '08067297449', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, '2015-03-21 11:46:14', '2015-03-21 10:52:19'),
(39, 'STF0039', 1, 'D.', 'NOSIKE', NULL, NULL, NULL, NULL, NULL, '08063095009', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, '2015-03-21 12:00:40', '2015-03-21 11:00:40'),
(40, 'STF0040', 1, '.', 'ADEOGUN', NULL, NULL, NULL, NULL, NULL, '08135469418', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 02:12:36', '2015-03-21 13:12:36'),
(41, 'STF0041', 1, ' J.', 'NWANI', NULL, NULL, NULL, NULL, NULL, '07066363009', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:09:36', '2015-03-21 16:09:37'),
(42, 'STF0042', 1, 'U.', 'NWANKWO', NULL, NULL, NULL, NULL, NULL, '08068345230', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:10:54', '2015-03-21 16:10:54'),
(43, 'STF0043', 2, ' B.', 'OBAJINMI', NULL, NULL, NULL, NULL, NULL, '07041144695', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:12:34', '2015-03-21 16:19:07'),
(44, 'STF0044', 3, 'C.', 'OBIANO', NULL, NULL, NULL, NULL, NULL, '08037687230', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:13:13', '2015-03-21 16:13:13'),
(45, 'STF0045', 3, 'A.', 'OGUNBOWALE', NULL, NULL, NULL, NULL, NULL, '08034656573', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:15:41', '2015-03-21 16:15:41'),
(46, 'STF0046', 4, 'M.', 'OGUNLEYE', NULL, NULL, NULL, NULL, NULL, '08035824686', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:22:15', '2015-03-21 16:22:16'),
(47, 'STF0047', 3, 'M.', 'OGUNSOLA', NULL, NULL, NULL, NULL, NULL, '07064500449', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:24:14', '2015-03-21 16:24:14'),
(48, 'STF0048', 4, 'A.', 'OJENIYI', NULL, NULL, NULL, NULL, NULL, '08062253157', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:26:32', '2015-03-21 16:26:33'),
(49, 'STF0049', 1, 'S.', 'OJETUNDE', NULL, NULL, NULL, NULL, NULL, '08025532237', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:27:16', '2015-03-21 16:27:16'),
(50, 'STF0050', 1, 'T.', 'OJO', NULL, NULL, NULL, NULL, NULL, '08036284758', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:27:56', '2015-03-21 16:27:56'),
(51, 'STF0051', 4, 'B.', 'OKECHUKWU-OMOLUABI', NULL, NULL, NULL, NULL, NULL, '08069277582', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:30:43', '2015-03-21 16:30:43'),
(52, 'STF0052', 3, 'I.', 'OKINI, ', NULL, NULL, NULL, NULL, NULL, '07069524725', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:31:48', '2015-03-21 16:31:48'),
(53, 'STF0053', 3, 'O.', 'OLAKANLE', NULL, NULL, NULL, NULL, NULL, '08062690908', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:32:40', '2015-03-21 16:32:41'),
(54, 'STF0054', 4, 'T.', 'OLATUNDE', NULL, NULL, NULL, NULL, NULL, '08035059758', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:44:30', '2015-03-21 16:44:30'),
(55, 'STF0055', 1, 'O.', 'OLAWOLE', NULL, NULL, NULL, NULL, NULL, '08035059087', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:47:53', '2015-03-21 16:47:53'),
(56, 'STF0056', 1, 'K.', 'ORIMOLADE', NULL, NULL, NULL, NULL, NULL, '08035484885', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:48:44', '2015-03-21 16:48:44'),
(57, 'STF0057', 4, 'A.', 'OWADOYE ', NULL, NULL, NULL, NULL, NULL, '08034387875', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:49:38', '2015-03-21 16:49:38'),
(58, 'STF0058', 4, 'T.', 'SOKOYA', NULL, NULL, NULL, NULL, NULL, '08167452006', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:50:21', '2015-03-21 16:50:21'),
(59, 'STF0059', 4, 'S.', 'TEMURU', NULL, NULL, NULL, NULL, NULL, '08027315354', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:53:25', '2015-03-21 16:53:25'),
(60, 'STF0060', 1, 'O.', 'UADEMEVBO', NULL, NULL, NULL, NULL, NULL, '07033473699', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:55:03', '2015-03-21 16:55:03'),
(61, 'STF0061', 1, 'L.', 'UDOKPORO', NULL, NULL, NULL, NULL, NULL, '08029087555', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:55:54', '2015-03-21 16:55:54'),
(62, 'STF0062', 1, 'A.', 'UMAR-MUHAMMED', NULL, NULL, NULL, NULL, NULL, '07062052814', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:57:28', '2015-03-21 17:04:56'),
(63, 'STF0063', 3, 'G.', 'USHIE', NULL, NULL, NULL, NULL, NULL, '08038703859', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:59:08', '2015-03-21 16:59:08'),
(64, 'STF0064', 1, 'Emmanuel', 'Okafor', NULL, NULL, NULL, NULL, NULL, '08061539278', NULL, NULL, NULL, NULL, NULL, 'nondefyde@gmail.com', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-22 02:15:37', '2015-03-22 13:15:37'),
(65, 'STF0065', 3, '.', 'Salau', NULL, NULL, NULL, NULL, NULL, '08128560399', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-24 08:52:59', '2015-03-24 07:52:59'),
(66, 'STF0066', 1, 'Ebikabo-Owei', 'ZIWORITIN', NULL, NULL, NULL, NULL, NULL, '07062522236', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 43, '2015-03-25 11:46:52', '2015-03-25 10:46:52'),
(67, 'STF0067', 4, '.', 'SU', NULL, NULL, NULL, NULL, NULL, '08077863953', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-26 09:19:43', '2015-03-26 08:19:43');

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=670 ;

--
-- Dumping data for table `exam_details`
--

INSERT INTO `exam_details` (`exam_detail_id`, `exam_id`, `student_id`, `ca1`, `ca2`, `exam`) VALUES
(1, 1, 118, '3.0', '13.0', '48.0'),
(2, 1, 129, '13.0', '15.0', '55.0'),
(3, 1, 131, '8.0', '3.0', '37.0'),
(4, 1, 137, '5.0', '3.0', '13.0'),
(5, 1, 138, '15.0', '13.0', '23.0'),
(6, 1, 140, '12.0', '12.0', '65.0'),
(7, 1, 142, '4.0', '8.0', '23.0'),
(8, 1, 143, '10.0', '12.0', '53.0'),
(9, 1, 144, '15.0', '3.0', '8.0'),
(10, 1, 145, '2.0', '6.0', '44.0'),
(16, 2, 22, '15.0', '7.0', '31.0'),
(17, 2, 28, '10.0', '4.0', '29.0'),
(18, 2, 31, '7.0', '11.0', '37.0'),
(19, 2, 38, '14.0', '15.0', '44.0'),
(20, 2, 43, '2.0', '15.0', '30.0'),
(23, 3, 118, '6.0', '12.0', '14.0'),
(24, 3, 129, '4.0', '14.0', '46.0'),
(25, 3, 131, '8.0', '9.0', '31.0'),
(26, 3, 137, '5.0', '8.0', '40.0'),
(27, 3, 138, '5.0', '9.0', '59.0'),
(28, 3, 140, '14.0', '8.0', '20.0'),
(29, 3, 142, '5.0', '3.0', '34.0'),
(30, 3, 143, '11.0', '9.0', '15.0'),
(31, 3, 144, '3.0', '7.0', '14.0'),
(32, 3, 145, '12.0', '7.0', '10.0'),
(33, 3, 284, '3.0', '11.0', '57.0'),
(38, 4, 30, '5.0', '14.0', '51.0'),
(39, 4, 33, '14.0', '7.0', '19.0'),
(40, 4, 34, '6.0', '10.0', '50.0'),
(41, 5, 1, '13.0', '14.0', '18.0'),
(42, 5, 2, '11.0', '12.0', '51.0'),
(43, 5, 3, '14.0', '2.0', '59.0'),
(44, 5, 4, '6.0', '11.0', '28.0'),
(45, 5, 5, '9.0', '13.0', '54.0'),
(46, 5, 6, '11.0', '9.0', '14.0'),
(47, 5, 7, '12.0', '11.0', '60.0'),
(48, 5, 10, '9.0', '15.0', '53.0'),
(49, 5, 11, '5.0', '14.0', '13.0'),
(50, 5, 12, '8.0', '4.0', '52.0'),
(51, 5, 13, '4.0', '2.0', '45.0'),
(52, 5, 14, '7.0', '11.0', '29.0'),
(53, 5, 15, '2.0', '10.0', '32.0'),
(54, 5, 16, '14.0', '15.0', '12.0'),
(55, 5, 17, '5.0', '8.0', '66.0'),
(56, 5, 18, '15.0', '3.0', '38.0'),
(72, 6, 169, '4.0', '14.0', '18.0'),
(73, 6, 177, '15.0', '7.0', '18.0'),
(74, 6, 178, '12.0', '11.0', '11.0'),
(75, 6, 179, '13.0', '3.0', '24.0'),
(79, 7, 57, '10.0', '5.0', '27.0'),
(80, 7, 58, '4.0', '10.0', '8.0'),
(81, 7, 59, '9.0', '11.0', '48.0'),
(82, 7, 60, '15.0', '10.0', '45.0'),
(83, 7, 63, '3.0', '14.0', '11.0'),
(84, 7, 65, '2.0', '14.0', '19.0'),
(86, 8, 248, '9.0', '2.0', '10.0'),
(87, 8, 249, '12.0', '15.0', '37.0'),
(88, 8, 250, '15.0', '12.0', '14.0'),
(89, 8, 251, '2.0', '9.0', '22.0'),
(90, 8, 253, '6.0', '3.0', '41.0'),
(91, 8, 254, '11.0', '6.0', '17.0'),
(92, 8, 255, '12.0', '14.0', '64.0'),
(93, 8, 256, '7.0', '13.0', '39.0'),
(94, 8, 257, '2.0', '14.0', '30.0'),
(95, 8, 258, '3.0', '15.0', '20.0'),
(96, 8, 259, '6.0', '8.0', '21.0'),
(97, 8, 260, '7.0', '4.0', '20.0'),
(98, 8, 261, '14.0', '3.0', '67.0'),
(99, 8, 262, '2.0', '4.0', '38.0'),
(100, 8, 263, '6.0', '8.0', '47.0'),
(101, 8, 264, '14.0', '4.0', '68.0'),
(102, 8, 265, '2.0', '14.0', '60.0'),
(103, 8, 266, '15.0', '5.0', '50.0'),
(104, 8, 267, '8.0', '5.0', '45.0'),
(105, 8, 268, '14.0', '7.0', '40.0'),
(117, 9, 197, '3.0', '11.0', '5.0'),
(118, 9, 198, '6.0', '3.0', '18.0'),
(119, 9, 199, '10.0', '2.0', '27.0'),
(120, 9, 202, '9.0', '3.0', '38.0'),
(121, 9, 204, '2.0', '7.0', '70.0'),
(122, 9, 227, '11.0', '6.0', '16.0'),
(123, 9, 228, '11.0', '7.0', '9.0'),
(124, 10, 93, '8.0', '6.0', '27.0'),
(125, 10, 96, '4.0', '13.0', '46.0'),
(126, 10, 98, '12.0', '11.0', '5.0'),
(127, 10, 100, '6.0', '13.0', '51.0'),
(128, 10, 102, '6.0', '3.0', '59.0'),
(129, 10, 104, '9.0', '12.0', '61.0'),
(130, 10, 106, '14.0', '5.0', '66.0'),
(131, 10, 109, '7.0', '6.0', '28.0'),
(132, 10, 110, '7.0', '15.0', '47.0'),
(133, 10, 111, '9.0', '10.0', '5.0'),
(134, 10, 112, '10.0', '3.0', '27.0'),
(135, 10, 113, '15.0', '6.0', '15.0'),
(136, 10, 114, '10.0', '3.0', '60.0'),
(137, 10, 115, '10.0', '7.0', '46.0'),
(138, 10, 116, '6.0', '12.0', '55.0'),
(139, 10, 117, '3.0', '5.0', '37.0'),
(140, 10, 119, '15.0', '4.0', '54.0'),
(141, 10, 134, '14.0', '9.0', '7.0'),
(142, 10, 136, '5.0', '14.0', '6.0'),
(143, 10, 139, '14.0', '8.0', '48.0'),
(155, 11, 120, '14.0', '3.0', '56.0'),
(156, 11, 121, '5.0', '2.0', '10.0'),
(157, 11, 122, '7.0', '10.0', '15.0'),
(158, 11, 123, '5.0', '4.0', '41.0'),
(159, 11, 132, '13.0', '8.0', '23.0'),
(160, 11, 133, '10.0', '10.0', '41.0'),
(161, 11, 135, '3.0', '9.0', '51.0'),
(162, 12, 21, '13.0', '8.0', '20.0'),
(163, 12, 180, '14.0', '11.0', '15.0'),
(164, 12, 181, '14.0', '10.0', '45.0'),
(165, 12, 182, '10.0', '8.0', '51.0'),
(166, 12, 183, '7.0', '12.0', '54.0'),
(167, 12, 184, '8.0', '3.0', '29.0'),
(168, 12, 185, '10.0', '6.0', '42.0'),
(169, 12, 186, '4.0', '4.0', '9.0'),
(170, 12, 187, '8.0', '12.0', '48.0'),
(171, 12, 188, '15.0', '14.0', '20.0'),
(177, 13, 141, '11.0', '11.0', '50.0'),
(178, 13, 221, '14.0', '10.0', '31.0'),
(179, 13, 222, '3.0', '9.0', '5.0'),
(180, 13, 224, '11.0', '3.0', '37.0'),
(181, 13, 225, '7.0', '8.0', '19.0'),
(182, 13, 226, '4.0', '14.0', '26.0'),
(183, 13, 229, '9.0', '8.0', '47.0'),
(184, 14, 95, '3.0', '11.0', '58.0'),
(185, 15, 48, '3.0', '3.0', '43.0'),
(186, 15, 50, '13.0', '2.0', '35.0'),
(187, 15, 51, '2.0', '12.0', '16.0'),
(188, 15, 52, '12.0', '11.0', '56.0'),
(189, 15, 55, '3.0', '12.0', '23.0'),
(190, 15, 56, '3.0', '8.0', '29.0'),
(192, 16, 20, '10.0', '13.0', '58.0'),
(193, 16, 279, '13.0', '15.0', '51.0'),
(195, 17, 232, '4.0', '8.0', '17.0'),
(196, 17, 233, '13.0', '10.0', '60.0'),
(197, 17, 234, '10.0', '11.0', '65.0'),
(198, 17, 236, '5.0', '9.0', '70.0'),
(199, 17, 238, '11.0', '9.0', '53.0'),
(200, 17, 242, '14.0', '5.0', '32.0'),
(201, 17, 243, '10.0', '7.0', '16.0'),
(202, 17, 244, '14.0', '9.0', '45.0'),
(203, 17, 246, '6.0', '4.0', '34.0'),
(204, 17, 247, '3.0', '2.0', '34.0'),
(210, 18, 66, '13.0', '5.0', '66.0'),
(211, 18, 67, '2.0', '2.0', '38.0'),
(212, 18, 68, '13.0', '11.0', '19.0'),
(213, 18, 69, '12.0', '14.0', '53.0'),
(214, 18, 70, '12.0', '10.0', '23.0'),
(215, 18, 71, '9.0', '8.0', '42.0'),
(216, 18, 72, '14.0', '3.0', '70.0'),
(217, 18, 73, '3.0', '2.0', '41.0'),
(218, 18, 74, '11.0', '6.0', '54.0'),
(219, 18, 75, '4.0', '8.0', '58.0'),
(220, 18, 76, '10.0', '5.0', '7.0'),
(221, 18, 77, '9.0', '5.0', '10.0'),
(222, 18, 78, '2.0', '3.0', '55.0'),
(223, 18, 79, '5.0', '14.0', '50.0'),
(224, 18, 80, '15.0', '11.0', '24.0'),
(225, 18, 81, '5.0', '4.0', '56.0'),
(226, 18, 82, '13.0', '3.0', '64.0'),
(227, 18, 83, '13.0', '4.0', '66.0'),
(228, 18, 84, '7.0', '14.0', '23.0'),
(241, 19, 22, '3.0', '2.0', '52.0'),
(242, 19, 26, '14.0', '10.0', '69.0'),
(243, 19, 28, '15.0', '3.0', '21.0'),
(244, 19, 31, '2.0', '4.0', '29.0'),
(245, 19, 32, '13.0', '7.0', '22.0'),
(246, 19, 36, '8.0', '7.0', '66.0'),
(247, 19, 37, '13.0', '11.0', '10.0'),
(248, 19, 38, '10.0', '9.0', '15.0'),
(249, 19, 39, '8.0', '6.0', '26.0'),
(250, 19, 40, '7.0', '11.0', '17.0'),
(251, 19, 41, '11.0', '13.0', '17.0'),
(252, 19, 42, '7.0', '12.0', '57.0'),
(253, 19, 43, '7.0', '11.0', '66.0'),
(254, 19, 44, '10.0', '11.0', '12.0'),
(255, 19, 45, '15.0', '9.0', '40.0'),
(256, 19, 46, '5.0', '2.0', '67.0'),
(257, 19, 47, '4.0', '13.0', '45.0'),
(258, 19, 252, '5.0', '7.0', '12.0'),
(272, 20, 137, '8.0', '14.0', '33.0'),
(273, 20, 138, '12.0', '5.0', '12.0'),
(274, 20, 140, '15.0', '15.0', '65.0'),
(275, 20, 142, '3.0', '7.0', '47.0'),
(276, 20, 143, '15.0', '12.0', '26.0'),
(277, 20, 144, '14.0', '7.0', '7.0'),
(278, 20, 145, '15.0', '7.0', '41.0'),
(279, 20, 284, '9.0', '10.0', '42.0'),
(287, 21, 24, '8.0', '13.0', '30.0'),
(288, 21, 25, '3.0', '3.0', '56.0'),
(289, 21, 27, '4.0', '9.0', '47.0'),
(290, 21, 29, '10.0', '5.0', '65.0'),
(291, 21, 30, '12.0', '5.0', '62.0'),
(292, 21, 33, '11.0', '7.0', '20.0'),
(293, 21, 34, '6.0', '6.0', '68.0'),
(294, 21, 35, '10.0', '4.0', '26.0'),
(295, 21, 203, '11.0', '4.0', '50.0'),
(302, 22, 1, '5.0', '11.0', '25.0'),
(303, 22, 2, '13.0', '3.0', '13.0'),
(304, 22, 3, '4.0', '4.0', '19.0'),
(305, 22, 4, '15.0', '7.0', '54.0'),
(306, 22, 5, '10.0', '2.0', '7.0'),
(307, 22, 6, '9.0', '12.0', '21.0'),
(308, 22, 7, '7.0', '8.0', '45.0'),
(309, 22, 10, '10.0', '12.0', '65.0'),
(310, 22, 11, '10.0', '7.0', '10.0'),
(311, 22, 12, '15.0', '3.0', '20.0'),
(312, 22, 13, '10.0', '6.0', '63.0'),
(313, 22, 14, '15.0', '3.0', '5.0'),
(314, 22, 15, '3.0', '6.0', '18.0'),
(315, 22, 16, '6.0', '6.0', '43.0'),
(316, 22, 17, '2.0', '14.0', '44.0'),
(317, 22, 18, '3.0', '8.0', '29.0'),
(333, 23, 269, '6.0', '14.0', '58.0'),
(334, 23, 271, '15.0', '9.0', '42.0'),
(335, 23, 272, '14.0', '3.0', '68.0'),
(336, 23, 273, '15.0', '2.0', '8.0'),
(337, 23, 274, '4.0', '11.0', '29.0'),
(338, 23, 275, '3.0', '10.0', '37.0'),
(339, 23, 276, '3.0', '11.0', '59.0'),
(340, 24, 57, '5.0', '15.0', '13.0'),
(341, 24, 58, '14.0', '2.0', '8.0'),
(342, 24, 59, '8.0', '3.0', '38.0'),
(343, 24, 60, '13.0', '8.0', '29.0'),
(344, 24, 61, '11.0', '7.0', '63.0'),
(345, 24, 62, '4.0', '5.0', '70.0'),
(346, 24, 63, '4.0', '5.0', '7.0'),
(347, 24, 64, '5.0', '7.0', '52.0'),
(348, 24, 65, '10.0', '8.0', '26.0'),
(355, 25, 167, '3.0', '9.0', '6.0'),
(356, 25, 169, '14.0', '13.0', '5.0'),
(357, 25, 172, '2.0', '11.0', '7.0'),
(358, 25, 173, '3.0', '4.0', '15.0'),
(359, 25, 174, '10.0', '2.0', '45.0'),
(362, 26, 57, '14.0', '2.0', '40.0'),
(363, 26, 58, '14.0', '6.0', '67.0'),
(364, 26, 59, '10.0', '14.0', '33.0'),
(365, 26, 60, '15.0', '15.0', '70.0'),
(366, 26, 61, '15.0', '14.0', '60.0'),
(367, 26, 62, '15.0', '15.0', '40.0'),
(368, 26, 63, '2.0', '3.0', '52.0'),
(369, 26, 64, '4.0', '11.0', '53.0'),
(370, 26, 65, '13.0', '11.0', '30.0'),
(377, 27, 259, '13.0', '9.0', '21.0'),
(378, 28, 197, '3.0', '7.0', '25.0'),
(379, 28, 199, '11.0', '6.0', '44.0'),
(380, 28, 200, '10.0', '15.0', '37.0'),
(381, 28, 205, '2.0', '14.0', '36.0'),
(385, 29, 98, '2.0', '14.0', '31.0'),
(386, 29, 111, '14.0', '13.0', '29.0'),
(387, 29, 112, '8.0', '13.0', '35.0'),
(388, 29, 136, '4.0', '2.0', '15.0'),
(392, 30, 19, '14.0', '13.0', '60.0'),
(393, 30, 120, '5.0', '10.0', '31.0'),
(394, 30, 121, '9.0', '12.0', '59.0'),
(395, 30, 122, '13.0', '8.0', '15.0'),
(396, 30, 123, '8.0', '3.0', '12.0'),
(397, 30, 124, '14.0', '3.0', '5.0'),
(398, 30, 125, '7.0', '4.0', '62.0'),
(399, 30, 126, '13.0', '2.0', '51.0'),
(400, 30, 127, '4.0', '8.0', '41.0'),
(401, 30, 128, '10.0', '11.0', '43.0'),
(402, 30, 130, '13.0', '9.0', '31.0'),
(403, 30, 132, '11.0', '12.0', '7.0'),
(404, 30, 133, '2.0', '6.0', '58.0'),
(405, 30, 135, '14.0', '3.0', '22.0'),
(407, 31, 103, '2.0', '9.0', '26.0'),
(408, 32, 141, '3.0', '8.0', '35.0'),
(409, 32, 221, '4.0', '14.0', '47.0'),
(410, 32, 222, '2.0', '11.0', '51.0'),
(411, 32, 224, '12.0', '14.0', '18.0'),
(412, 32, 225, '6.0', '9.0', '60.0'),
(413, 32, 226, '14.0', '6.0', '29.0'),
(414, 32, 229, '5.0', '15.0', '14.0'),
(415, 32, 230, '6.0', '2.0', '35.0'),
(416, 32, 231, '3.0', '14.0', '44.0'),
(423, 33, 277, '7.0', '15.0', '16.0'),
(424, 34, 48, '11.0', '3.0', '48.0'),
(425, 34, 49, '4.0', '5.0', '41.0'),
(426, 34, 50, '13.0', '5.0', '21.0'),
(427, 34, 51, '9.0', '15.0', '14.0'),
(428, 34, 52, '11.0', '5.0', '48.0'),
(429, 34, 53, '9.0', '4.0', '70.0'),
(430, 34, 54, '14.0', '7.0', '68.0'),
(431, 34, 55, '2.0', '12.0', '69.0'),
(432, 34, 56, '9.0', '13.0', '62.0'),
(439, 35, 206, '3.0', '4.0', '57.0'),
(440, 35, 207, '6.0', '14.0', '62.0'),
(441, 35, 208, '15.0', '3.0', '11.0'),
(442, 35, 209, '9.0', '14.0', '27.0'),
(443, 35, 210, '12.0', '7.0', '26.0'),
(444, 35, 211, '14.0', '3.0', '43.0'),
(445, 35, 212, '9.0', '11.0', '53.0'),
(446, 35, 213, '9.0', '9.0', '14.0'),
(447, 35, 214, '9.0', '10.0', '62.0'),
(448, 35, 215, '8.0', '4.0', '51.0'),
(449, 35, 216, '6.0', '5.0', '65.0'),
(450, 35, 217, '4.0', '9.0', '59.0'),
(451, 35, 218, '2.0', '9.0', '64.0'),
(452, 35, 219, '3.0', '2.0', '56.0'),
(453, 35, 220, '8.0', '12.0', '16.0'),
(454, 36, 68, '12.0', '11.0', '23.0'),
(455, 36, 69, '7.0', '5.0', '66.0'),
(456, 36, 70, '3.0', '13.0', '38.0'),
(457, 36, 71, '5.0', '6.0', '14.0'),
(458, 36, 72, '3.0', '12.0', '25.0'),
(459, 36, 73, '13.0', '3.0', '43.0'),
(460, 36, 74, '12.0', '5.0', '15.0'),
(461, 36, 75, '10.0', '6.0', '49.0'),
(462, 36, 76, '8.0', '7.0', '50.0'),
(463, 36, 78, '5.0', '14.0', '35.0'),
(464, 36, 79, '8.0', '11.0', '14.0'),
(465, 36, 80, '12.0', '2.0', '30.0'),
(466, 36, 83, '11.0', '4.0', '16.0'),
(467, 36, 84, '4.0', '7.0', '36.0'),
(469, 37, 22, '6.0', '9.0', '21.0'),
(470, 37, 26, '10.0', '7.0', '29.0'),
(471, 37, 28, '4.0', '3.0', '47.0'),
(472, 37, 31, '7.0', '12.0', '66.0'),
(473, 37, 32, '2.0', '5.0', '28.0'),
(474, 37, 36, '12.0', '8.0', '20.0'),
(475, 37, 37, '4.0', '15.0', '64.0'),
(476, 37, 38, '6.0', '11.0', '67.0'),
(477, 37, 39, '12.0', '7.0', '11.0'),
(478, 37, 40, '14.0', '9.0', '38.0'),
(479, 37, 41, '7.0', '13.0', '8.0'),
(480, 37, 43, '10.0', '8.0', '33.0'),
(481, 37, 44, '15.0', '11.0', '43.0'),
(482, 37, 45, '10.0', '2.0', '25.0'),
(483, 37, 46, '9.0', '3.0', '39.0'),
(484, 37, 47, '14.0', '13.0', '6.0'),
(485, 37, 252, '3.0', '2.0', '68.0'),
(500, 38, 142, '2.0', '6.0', '48.0'),
(501, 38, 143, '15.0', '2.0', '6.0'),
(502, 38, 144, '3.0', '15.0', '41.0'),
(503, 38, 145, '10.0', '6.0', '31.0'),
(507, 39, 24, '11.0', '15.0', '63.0'),
(508, 39, 27, '3.0', '14.0', '43.0'),
(509, 39, 29, '11.0', '9.0', '47.0'),
(510, 39, 30, '15.0', '2.0', '54.0'),
(511, 39, 33, '9.0', '15.0', '42.0'),
(512, 39, 34, '9.0', '3.0', '43.0'),
(513, 39, 35, '8.0', '3.0', '66.0'),
(514, 40, 1, '4.0', '3.0', '5.0'),
(515, 40, 2, '4.0', '4.0', '69.0'),
(516, 40, 4, '12.0', '13.0', '24.0'),
(517, 40, 5, '3.0', '8.0', '20.0'),
(518, 40, 6, '2.0', '9.0', '14.0'),
(519, 40, 12, '10.0', '5.0', '48.0'),
(520, 40, 14, '5.0', '5.0', '52.0'),
(521, 40, 17, '15.0', '12.0', '49.0'),
(522, 40, 18, '9.0', '5.0', '55.0'),
(529, 41, 192, '4.0', '12.0', '63.0'),
(530, 41, 196, '3.0', '14.0', '5.0'),
(532, 42, 57, '3.0', '2.0', '19.0'),
(533, 42, 58, '2.0', '12.0', '6.0'),
(534, 42, 60, '7.0', '14.0', '37.0'),
(535, 42, 61, '10.0', '14.0', '9.0'),
(536, 42, 62, '12.0', '9.0', '25.0'),
(537, 42, 63, '7.0', '12.0', '40.0'),
(538, 42, 64, '3.0', '12.0', '23.0'),
(539, 42, 65, '13.0', '6.0', '40.0'),
(547, 43, 259, '9.0', '8.0', '24.0'),
(548, 44, 197, '8.0', '10.0', '18.0'),
(549, 44, 198, '8.0', '11.0', '22.0'),
(550, 44, 199, '11.0', '12.0', '8.0'),
(551, 44, 200, '11.0', '3.0', '68.0'),
(552, 44, 201, '4.0', '12.0', '63.0'),
(553, 44, 202, '5.0', '8.0', '32.0'),
(554, 44, 204, '9.0', '14.0', '17.0'),
(555, 44, 205, '3.0', '2.0', '68.0'),
(556, 44, 223, '7.0', '13.0', '24.0'),
(557, 44, 227, '15.0', '6.0', '57.0'),
(558, 44, 228, '5.0', '13.0', '29.0'),
(563, 45, 102, '8.0', '5.0', '8.0'),
(564, 45, 110, '11.0', '14.0', '58.0'),
(566, 46, 197, '12.0', '10.0', '67.0'),
(567, 46, 198, '12.0', '12.0', '49.0'),
(568, 46, 199, '10.0', '2.0', '14.0'),
(569, 46, 200, '2.0', '10.0', '6.0'),
(570, 46, 201, '4.0', '11.0', '7.0'),
(571, 46, 202, '4.0', '3.0', '59.0'),
(572, 46, 204, '8.0', '2.0', '16.0'),
(573, 46, 205, '5.0', '5.0', '69.0'),
(574, 46, 223, '10.0', '11.0', '19.0'),
(575, 46, 227, '11.0', '7.0', '13.0'),
(576, 46, 228, '8.0', '3.0', '52.0'),
(581, 47, 102, '8.0', '13.0', '38.0'),
(582, 47, 110, '3.0', '8.0', '40.0'),
(583, 47, 111, '5.0', '8.0', '13.0'),
(584, 47, 113, '6.0', '11.0', '60.0'),
(585, 47, 116, '6.0', '13.0', '66.0'),
(588, 48, 141, '4.0', '5.0', '67.0'),
(589, 48, 221, '6.0', '9.0', '17.0'),
(590, 48, 222, '6.0', '4.0', '62.0'),
(591, 48, 224, '9.0', '13.0', '21.0'),
(592, 48, 225, '11.0', '6.0', '30.0'),
(593, 48, 226, '7.0', '12.0', '20.0'),
(594, 48, 229, '14.0', '14.0', '50.0'),
(595, 48, 230, '7.0', '3.0', '14.0'),
(603, 49, 89, '9.0', '8.0', '58.0'),
(604, 49, 91, '7.0', '12.0', '47.0'),
(605, 49, 92, '6.0', '14.0', '66.0'),
(606, 49, 99, '5.0', '5.0', '35.0'),
(607, 49, 103, '8.0', '9.0', '45.0'),
(608, 49, 108, '6.0', '2.0', '34.0'),
(610, 50, 48, '10.0', '11.0', '56.0'),
(611, 50, 49, '15.0', '3.0', '40.0'),
(612, 50, 50, '4.0', '15.0', '33.0'),
(613, 50, 51, '14.0', '7.0', '42.0'),
(614, 50, 52, '2.0', '14.0', '5.0'),
(615, 50, 53, '14.0', '6.0', '54.0'),
(616, 50, 54, '9.0', '10.0', '47.0'),
(617, 50, 55, '7.0', '14.0', '63.0'),
(618, 50, 56, '14.0', '7.0', '32.0'),
(625, 51, 20, '8.0', '11.0', '36.0'),
(626, 52, 232, '15.0', '6.0', '17.0'),
(627, 52, 233, '11.0', '5.0', '22.0'),
(628, 52, 234, '5.0', '8.0', '20.0'),
(629, 52, 235, '11.0', '6.0', '45.0'),
(630, 52, 236, '5.0', '7.0', '40.0'),
(631, 52, 237, '5.0', '5.0', '61.0'),
(632, 52, 238, '2.0', '12.0', '37.0'),
(633, 52, 239, '11.0', '4.0', '30.0'),
(634, 52, 240, '9.0', '3.0', '55.0'),
(635, 52, 241, '15.0', '9.0', '35.0'),
(636, 52, 242, '7.0', '9.0', '55.0'),
(637, 52, 243, '10.0', '4.0', '6.0'),
(638, 52, 244, '14.0', '8.0', '36.0'),
(639, 52, 245, '3.0', '4.0', '60.0'),
(640, 52, 246, '12.0', '7.0', '20.0'),
(641, 52, 247, '5.0', '11.0', '37.0'),
(657, 53, 210, '3.0', '11.0', '21.0'),
(658, 53, 213, '10.0', '6.0', '34.0'),
(660, 54, 66, '15.0', '13.0', '38.0'),
(661, 54, 67, '12.0', '13.0', '10.0'),
(662, 54, 72, '4.0', '5.0', '43.0'),
(663, 54, 76, '15.0', '13.0', '57.0'),
(664, 54, 80, '15.0', '12.0', '21.0'),
(665, 54, 81, '8.0', '13.0', '31.0'),
(666, 54, 82, '6.0', '9.0', '57.0'),
(667, 25, 168, '0.0', '0.0', '0.0'),
(668, 25, 176, '0.0', '0.0', '0.0'),
(669, 25, 179, '0.0', '0.0', '0.0');

-- --------------------------------------------------------

--
-- Stand-in structure for view `exam_subjectviews`
--
CREATE TABLE IF NOT EXISTS `exam_subjectviews` (
`exam_id` int(11) unsigned
,`class_id` int(11)
,`class_name` varchar(50)
,`subject_name` varchar(50)
,`subject_id` int(11)
,`subject_classlevel_id` int(11)
,`weightageCA1` int(10) unsigned
,`weightageCA2` int(10) unsigned
,`weightageExam` int(10) unsigned
,`exammarked_status_id` int(11)
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
  `class_id` int(11) DEFAULT NULL,
  `subject_classlevel_id` int(11) DEFAULT NULL,
  `exammarked_status_id` int(11) DEFAULT '2'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=55 ;

--
-- Dumping data for table `exams`
--

INSERT INTO `exams` (`exam_id`, `class_id`, `subject_classlevel_id`, `exammarked_status_id`) VALUES
(1, 1, 15, 1),
(2, 14, 146, 1),
(3, 1, 196, 1),
(4, 15, 146, 1),
(5, 2, 196, 1),
(6, 20, 56, 1),
(7, 4, 143, 1),
(8, 22, 98, 1),
(9, 5, 112, 1),
(10, 24, 98, 1),
(11, 7, 145, 1),
(12, 25, 98, 1),
(13, 9, 145, 1),
(14, 29, 178, 1),
(15, 10, 145, 1),
(16, 30, 178, 1),
(17, 11, 146, 1),
(18, 13, 17, 1),
(19, 14, 17, 1),
(20, 1, 112, 1),
(21, 15, 17, 1),
(22, 2, 15, 1),
(23, 17, 172, 1),
(24, 4, 15, 1),
(25, 20, 172, 1),
(26, 4, 196, 1),
(27, 22, 179, 1),
(28, 5, 143, 1),
(29, 24, 116, 1),
(30, 7, 197, 1),
(31, 29, 60, 1),
(32, 9, 197, 1),
(33, 30, 60, 1),
(34, 10, 197, 1),
(35, 12, 17, 1),
(36, 13, 114, 1),
(37, 14, 114, 1),
(38, 1, 143, 1),
(39, 15, 114, 1),
(40, 2, 143, 1),
(41, 19, 115, 1),
(42, 4, 112, 1),
(43, 22, 57, 1),
(44, 5, 15, 1),
(45, 24, 57, 1),
(46, 5, 196, 1),
(47, 24, 179, 1),
(48, 9, 113, 1),
(49, 29, 117, 1),
(50, 10, 16, 1),
(51, 30, 117, 1),
(52, 11, 17, 1),
(53, 12, 146, 1),
(54, 13, 146, 1);

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
,`weightageCA1` int(10) unsigned
,`weightageCA2` int(10) unsigned
,`weightageExam` int(10) unsigned
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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=14 ;

--
-- Dumping data for table `grades`
--

INSERT INTO `grades` (`grades_id`, `grade`, `grade_abbr`, `classgroup_id`, `lower_bound`, `upper_bound`) VALUES
(1, 'DISTINCTION', 'A', 1, '70.0', '100.0'),
(2, 'CREDIT', 'C', 1, '50.0', '69.0'),
(3, 'PASS', 'P', 1, '40.0', '49.0'),
(4, 'FAIL', 'F', 1, '0.0', '39.0'),
(5, 'EXCELLENT', 'A1', 2, '75.0', '100.0'),
(6, 'VERY GOOD', 'B2', 2, '70.0', '74.0'),
(7, 'GOOD', 'B3', 2, '65.0', '69.0'),
(8, 'CREDIT', 'C4', 2, '60.0', '64.0'),
(9, 'CREDIT', 'C5', 2, '55.0', '59.0'),
(10, 'CREDIT', 'C6', 2, '50.0', '54.0'),
(11, 'PASS', 'D7', 2, '45.0', '49.0'),
(12, 'PASS', 'E8', 2, '40.0', '44.0'),
(13, 'FAIL', 'F9', 2, '0.0', '39.0');

-- --------------------------------------------------------

--
-- Table structure for table `item_bills`
--

CREATE TABLE IF NOT EXISTS `item_bills` (
`item_bill_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `price` decimal(12,2) NOT NULL,
  `classlevel_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

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
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

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
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

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
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

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
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

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
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

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
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `process_items`
--

CREATE TABLE IF NOT EXISTS `process_items` (
`process_item_id` int(11) NOT NULL,
  `process_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `process_by` int(11) NOT NULL,
  `academic_term_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

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
-- Table structure for table `remarks`
--

CREATE TABLE IF NOT EXISTS `remarks` (
`remark_id` int(11) NOT NULL,
  `class_teacher_remark` varchar(300) NOT NULL DEFAULT 'None',
  `house_master_remark` varchar(300) DEFAULT 'None',
  `principal_remark` varchar(300) DEFAULT 'None',
  `student_id` int(11) NOT NULL,
  `academic_term_id` int(11) NOT NULL,
  `employee_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

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
(4, 'Mrs', 'Mrs.'),
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
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

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
  `other_name` varchar(50) DEFAULT NULL,
  `first_name` varchar(50) DEFAULT NULL,
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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=274 ;

--
-- Dumping data for table `sponsors`
--

INSERT INTO `sponsors` (`sponsor_id`, `sponsor_no`, `other_name`, `first_name`, `salutation_id`, `occupation`, `company_name`, `company_address`, `email`, `image_url`, `contact_address`, `local_govt_id`, `state_id`, `country_id`, `mobile_number1`, `mobile_number2`, `created_by`, `sponsorship_type_id`, `created_at`, `updated_at`) VALUES
(1, 'PAR0001', 'Stanley', 'Ogbuchi', 1, NULL, NULL, NULL, 'ogbuchistanley@rocketmail.com', NULL, NULL, NULL, NULL, NULL, '08180966334', NULL, 1, NULL, '2015-03-19 02:11:34', '2015-03-19 13:11:34'),
(2, 'PAR0002', 'JOSEPH', 'ADENIRAN', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08055492870', NULL, 1, NULL, '2015-03-19 06:57:19', '2015-03-22 23:13:48'),
(3, 'PAR0003', 'BANKOLE', 'ATUNRASE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08028861077', NULL, 1, NULL, '2015-03-19 06:58:57', '2015-03-22 23:14:26'),
(4, 'PAR0004', 'PHOS BAYOWA', 'BAIYEKUSI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08088080606', NULL, 1, NULL, '2015-03-19 07:00:53', '2015-03-22 23:17:33'),
(5, 'PAR0005', 'OLUWATOFARATI DAVID', 'BAKRE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023056956', NULL, 1, NULL, '2015-03-19 07:02:41', '2015-03-22 23:18:38'),
(6, 'PAR0006', 'MOSES', 'BALOGUN', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033249151', NULL, 1, NULL, '2015-03-19 07:04:50', '2015-03-22 23:19:33'),
(7, 'PAR0007', 'NATHAN', 'BAYOKO', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033228548', NULL, 1, NULL, '2015-03-19 07:12:26', '2015-03-22 23:36:49'),
(8, 'PAR0008', 'SAMUEL', 'EGBEDEYI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023006777', NULL, 1, NULL, '2015-03-19 07:20:00', '2015-03-22 23:37:49'),
(9, 'PAR0009', 'DAVID', 'HENRY-NKEKI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08123000064', NULL, 1, NULL, '2015-03-19 07:36:10', '2015-03-22 23:38:24'),
(10, 'PAR0010', 'DAVID', 'IBILOLA', 1, NULL, NULL, NULL, 'richardibilola@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033573649', NULL, 1, NULL, '2015-03-19 07:37:47', '2015-03-22 23:38:45'),
(11, 'PAR0011', 'OLANREWAJU', 'NICK-IBITOYE ', 1, NULL, NULL, NULL, 'nick.ibitoye@shell.com', NULL, NULL, NULL, NULL, NULL, '08035500298', NULL, 1, NULL, '2015-03-19 07:42:44', '2015-03-22 23:40:14'),
(12, 'PAR0012', 'VICTOR', 'NKUME-ANYIGOR ', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07033469369', NULL, 1, NULL, '2015-03-19 07:46:39', '2015-03-22 23:52:18'),
(13, 'PAR0013', 'CHUKWUKA', 'OFOEGBUNAM', 1, NULL, NULL, NULL, 'tmotrading@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08035755653', NULL, 1, NULL, '2015-03-19 07:51:38', '2015-03-22 23:54:21'),
(14, 'PAR0014', 'JOSHUA', 'OGHOORE', 1, NULL, NULL, NULL, 'oviemuno2002@yahoo.co.uk', NULL, NULL, NULL, NULL, NULL, '08033083745', NULL, 1, NULL, '2015-03-19 07:55:38', '2015-03-22 23:55:32'),
(15, 'PAR0015', 'ADEYEMI', 'OLAGUNJU', 1, NULL, NULL, NULL, 'homeinnlux@gmail.com', NULL, NULL, NULL, NULL, NULL, '08037697680', NULL, 1, NULL, '2015-03-19 07:57:44', '2015-03-22 23:56:25'),
(16, 'PAR0016', 'OLANREWAJU JOSEPH', 'OLATUNBOSUN', 1, NULL, NULL, NULL, 'loladeboy@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08028723456', NULL, 1, NULL, '2015-03-19 08:01:47', '2015-03-22 23:56:53'),
(17, 'PAR0017', 'AYODELE', 'YUSUF', 1, NULL, NULL, NULL, 'olabisiakinlabi@gmail.com', NULL, NULL, NULL, NULL, NULL, '08023401123', NULL, 1, NULL, '2015-03-19 08:03:41', '2015-03-23 00:11:06'),
(25, 'PAR0025', 'Oladapo', 'Ajayi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08020593133', NULL, 13, NULL, '2015-03-24 10:17:45', '2015-03-24 09:17:45'),
(26, 'PAR0026', 'Opeyemi', 'Opeyemi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08189145603', NULL, 53, NULL, '2015-03-24 10:23:45', '2015-03-24 15:58:04'),
(29, 'PAR0029', 'Adegboyega', 'Williams', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08189145603', NULL, 53, NULL, '2015-03-24 10:49:42', '2015-03-24 09:49:42'),
(30, 'PAR0030', 'Ifeoluwa', 'Adealu', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023006122', NULL, 40, NULL, '2015-03-24 11:08:11', '2015-03-24 10:08:11'),
(32, 'PAR0032', 'KEME', 'ABADI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08063753985', NULL, 30, NULL, '2015-03-24 11:21:47', '2015-03-24 10:21:47'),
(34, 'PAR0034', 'EBIKABOERE', 'AMARA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07038743024', NULL, 30, NULL, '2015-03-24 11:25:10', '2015-03-24 10:25:10'),
(35, 'PAR0035', 'CHIAMAKA', 'ANIWETA-NEZIANYA', 8, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08035900798', NULL, 30, NULL, '2015-03-24 11:26:48', '2015-03-24 10:26:48'),
(36, 'PAR0036', 'KENDRAH', 'BAGOU', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08031902363', NULL, 30, NULL, '2015-03-24 11:28:15', '2015-03-24 10:28:15'),
(37, 'PAR0037', 'OKEOGHENE', 'ERIVWODE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08066766565', NULL, 30, NULL, '2015-03-24 11:29:35', '2015-03-24 10:29:35'),
(38, 'PAR0038', 'AYEBANENGIYEFA', 'GEORGEWILL', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037968795', NULL, 30, NULL, '2015-03-24 11:30:56', '2015-03-24 10:30:56'),
(39, 'PAR0039', 'ROSEMARY', 'ITSEUWA ', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033215262', NULL, 30, NULL, '2015-03-24 11:32:20', '2015-03-24 10:32:20'),
(40, 'PAR0040', 'VICTORIA', 'JOB', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08135591296', NULL, 30, NULL, '2015-03-24 11:33:22', '2015-03-24 10:33:23'),
(41, 'PAR0041', 'HAPPINESS', 'KALAYOLO', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07062687122', NULL, 30, NULL, '2015-03-24 11:34:25', '2015-03-24 10:34:25'),
(42, 'PAR0042', 'ONISOKIE', 'MAZI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037899243', NULL, 30, NULL, '2015-03-24 11:36:03', '2015-03-24 10:36:03'),
(43, 'PAR0043', 'EVELYN', 'NATHANIEL', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08131346013', NULL, 30, NULL, '2015-03-24 11:37:04', '2015-03-24 10:37:04'),
(44, 'PAR0044', 'OYINKANSOLA', 'OBUBE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08067183793', NULL, 30, NULL, '2015-03-24 11:37:58', '2015-03-24 10:37:58'),
(45, 'PAR0045', 'OYINDAMOLA', 'OKE', 11, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08090906406', NULL, 30, NULL, '2015-03-24 11:38:54', '2015-03-24 10:38:54'),
(46, 'PAR0046', 'Jimoh', 'Otori', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023070934', NULL, 53, NULL, '2015-03-24 11:39:32', '2015-03-24 10:39:32'),
(47, 'PAR0047', 'CHISOM', 'OKOYE', 6, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023376269', NULL, 30, NULL, '2015-03-24 11:39:55', '2015-03-24 10:39:55'),
(48, 'PAR0048', 'Funke', 'Salau', 4, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023288942', NULL, 53, NULL, '2015-03-24 11:41:13', '2015-03-24 10:41:14'),
(49, 'PAR0049', 'IBEINMO', 'TELIMOYE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07037722998', NULL, 30, NULL, '2015-03-24 11:41:32', '2015-03-24 10:41:32'),
(50, 'PAR0050', 'Moruf', 'Adealu', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023006122', NULL, 53, NULL, '2015-03-24 11:42:50', '2015-03-24 10:42:50'),
(51, 'PAR0051', 'ENDURANCE', 'WAIBITE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08168189756', NULL, 30, NULL, '2015-03-24 11:44:42', '2015-03-24 10:44:43'),
(52, 'PAR0052', 'Oluwagbenga', 'Ojo', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023318436', NULL, 53, NULL, '2015-03-24 11:45:33', '2015-03-24 10:45:33'),
(53, 'PAR0053', 'IBUKUN', 'WILLIAMS', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08038404056', NULL, 30, NULL, '2015-03-24 11:45:38', '2015-03-24 10:45:38'),
(54, 'PAR0054', 'Adekunle', 'Oloyede', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08024001476', NULL, 53, NULL, '2015-03-24 11:46:23', '2015-03-24 10:46:23'),
(55, 'PAR0055', 'Oyinlade', 'Abioye', 4, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023328277', NULL, 53, NULL, '2015-03-24 11:47:30', '2015-03-24 10:47:30'),
(56, 'PAR0056', 'Jelili', 'Odesola', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08061663367', NULL, 53, NULL, '2015-03-24 11:48:22', '2015-03-24 10:48:22'),
(57, 'PAR0057', 'Oladapo', 'ADEOSUN', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023125717', NULL, 52, NULL, '2015-03-24 12:17:24', '2015-03-24 11:17:24'),
(58, 'PAR0058', 'MUBARAK', 'DADA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08026829359', NULL, 52, NULL, '2015-03-24 12:18:11', '2015-03-24 11:18:11'),
(59, 'PAR0059', 'MICHEAL', 'ADEDOTUN', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08085439241', NULL, 52, NULL, '2015-03-24 12:19:09', '2015-03-24 11:19:10'),
(60, 'PAR0060', 'DEBORAH', 'AGUNBIADE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '09034109157', NULL, 52, NULL, '2015-03-24 12:21:48', '2015-03-24 11:21:48'),
(61, 'PAR0061', 'Adekunle', 'HAMZAT', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '080233359199', NULL, 52, NULL, '2015-03-24 12:22:32', '2015-03-24 11:22:33'),
(62, 'PAR0062', 'EMMANUEL', 'LALA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08034015407', NULL, 52, NULL, '2015-03-24 12:23:09', '2015-03-24 11:23:10'),
(63, 'PAR0063', 'ADESOJI', 'OKESINA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08062883453', NULL, 52, NULL, '2015-03-24 12:23:48', '2015-03-24 11:23:48'),
(64, 'PAR0064', 'JOSEPH', 'OJO', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023176070', NULL, 52, NULL, '2015-03-24 12:24:29', '2015-03-24 11:24:30'),
(65, 'PAR0065', 'IBAZEBO', 'ADENIYI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023193180', NULL, 52, NULL, '2015-03-24 12:40:25', '2015-03-24 11:40:25'),
(66, 'PAR0066', 'Olufemi', 'Azeez', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08189268578', NULL, 14, NULL, '2015-03-24 12:49:56', '2015-03-24 11:49:57'),
(67, 'PAR0067', 'Tajudeen', 'Bello', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08092855295', NULL, 14, NULL, '2015-03-24 12:50:43', '2015-03-24 11:50:43'),
(68, 'PAR0068', 'Aderemi', 'Bello', 8, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08035103728', NULL, 14, NULL, '2015-03-24 12:51:49', '2015-03-24 11:51:49'),
(69, 'PAR0069', 'Kelvin', 'Bribena', 5, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08168800002', NULL, 14, NULL, '2015-03-24 12:52:39', '2015-03-24 11:52:39'),
(70, 'PAR0070', 'Isaac', 'Folorunso', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023120561', NULL, 14, NULL, '2015-03-24 12:55:00', '2015-03-24 11:55:00'),
(71, 'PAR0071', 'Amos', 'Ogundele', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08025015608', NULL, 14, NULL, '2015-03-24 12:55:31', '2015-03-24 11:55:31'),
(72, 'PAR0072', 'Oyekanmi', 'Olaoye', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08057932322', NULL, 14, NULL, '2015-03-24 12:56:12', '2015-03-24 11:56:12'),
(73, 'PAR0073', 'Edwin', 'Onyebuchi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033008296', NULL, 14, NULL, '2015-03-24 12:57:04', '2015-03-24 11:57:04'),
(74, 'PAR0074', 'Adaobi', 'Eze', 6, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033017899', NULL, 14, NULL, '2015-03-24 01:00:05', '2015-03-24 12:00:05'),
(75, 'PAR0075', 'Humphrey', 'Ibetei', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08062893168', NULL, 44, NULL, '2015-03-24 01:24:31', '2015-03-24 12:24:31'),
(76, 'PAR0076', 'Reginald', 'Dede', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08130786804', NULL, 44, NULL, '2015-03-24 01:25:40', '2015-03-24 12:25:40'),
(77, 'PAR0077', 'Fatiou', 'Abdou', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '22997224403', NULL, 44, NULL, '2015-03-24 01:28:24', '2015-03-24 12:28:24'),
(78, 'PAR0078', 'Osoru', 'Obireke', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08035185309', NULL, 44, NULL, '2015-03-24 01:29:12', '2015-03-24 12:29:12'),
(79, 'PAR0079', 'Solomon', 'Umoru', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08022030333', NULL, 44, NULL, '2015-03-24 01:30:08', '2015-03-24 12:30:09'),
(80, 'PAR0080', 'Smdoth', 'Nanakede', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08088657546', NULL, 44, NULL, '2015-03-24 01:32:02', '2015-03-24 12:32:03'),
(81, 'PAR0081', 'Bob', 'puragha', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08038921816', NULL, 44, NULL, '2015-03-24 01:33:19', '2015-03-24 12:33:19'),
(82, 'PAR0082', 'Anthony', 'Soroh', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08069760970', NULL, 44, NULL, '2015-03-24 01:34:06', '2015-03-24 12:34:07'),
(83, 'PAR0083', 'Christopher', 'Maddocks', 3, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08069097498', NULL, 44, NULL, '2015-03-24 01:34:59', '2015-03-24 12:34:59'),
(84, 'PAR0084', 'Osahon', 'Isibor', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07086455645', NULL, 44, NULL, '2015-03-24 01:35:43', '2015-03-24 12:35:43'),
(85, 'PAR0085', 'Joshua', 'Zolo', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032124113', NULL, 44, NULL, '2015-03-24 01:37:22', '2015-03-24 12:37:22'),
(86, 'PAR0086', 'Ebikabo', 'Koroye ', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037375525', NULL, 44, NULL, '2015-03-24 01:38:31', '2015-03-24 12:38:32'),
(87, 'PAR0087', 'Moneyman', 'Amakedi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08053397636', NULL, 44, NULL, '2015-03-24 01:39:27', '2015-03-24 12:39:28'),
(88, 'PAR0088', 'Sunday', 'Azugha', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '080379911959', NULL, 44, NULL, '2015-03-24 01:40:04', '2015-03-24 12:40:04'),
(89, 'PAR0089', 'Saadu', 'Abdullahi', 1, NULL, NULL, NULL, 'abdusaadu@yahoo.co.uk', NULL, NULL, NULL, NULL, NULL, '08033026256', NULL, 65, NULL, '2015-03-24 01:40:06', '2015-03-24 12:40:06'),
(90, 'PAR0090', 'Abdul', 'Inenemo-Usman', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08035351939', NULL, 44, NULL, '2015-03-24 01:41:00', '2015-03-24 12:41:00'),
(91, 'PAR0091', 'J.A', 'adeyemi', 8, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08068678683', NULL, 65, NULL, '2015-03-24 01:41:01', '2015-03-24 12:41:02'),
(92, 'PAR0092', 'Abdul', 'Adewole', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023154167', NULL, 44, NULL, '2015-03-24 01:41:40', '2015-03-24 12:41:41'),
(94, 'PAR0094', 'olakunle', 'kushimo', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023434661', NULL, 60, NULL, '2015-03-24 01:43:36', '2015-03-24 12:43:36'),
(95, 'PAR0095', 'Azibabhom', 'Sam-Micheal', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07032420601', NULL, 44, NULL, '2015-03-24 01:43:46', '2015-03-24 12:43:47'),
(96, 'PAR0096', 'adesoji', 'ajibode', 1, NULL, NULL, NULL, 'cedarlinks2001@yahoo.com', NULL, NULL, NULL, NULL, NULL, '07034077523', NULL, 65, NULL, '2015-03-24 01:44:21', '2015-03-24 12:44:21'),
(97, 'PAR0097', 'Ayibatare', 'Bagou', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08063509486', NULL, 44, NULL, '2015-03-24 01:44:58', '2015-03-24 12:44:58'),
(98, 'PAR0098', 'omolade', 'faloye', 1, NULL, NULL, NULL, 'omoladefaloye@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08023193280', NULL, 65, NULL, '2015-03-24 01:45:33', '2015-03-24 12:45:33'),
(100, 'PAR0100', 'Nike', 'Isikpi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08069760970', NULL, 44, NULL, '2015-03-24 01:47:14', '2015-03-24 12:47:14'),
(101, 'PAR0101', 'lina', 'orhiunu', 4, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '447930347074', NULL, 65, NULL, '2015-03-24 01:47:23', '2015-03-24 12:47:23'),
(102, 'PAR0102', 'o.o', 'imasuen', 1, NULL, NULL, NULL, 'femimasuen@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08022234476', NULL, 65, NULL, '2015-03-24 01:48:36', '2015-03-24 12:48:37'),
(103, 'PAR0103', 'Muhsin', 'Momoh', 5, NULL, NULL, NULL, 'amomoh@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033313424', NULL, 43, NULL, '2015-03-24 01:49:33', '2015-03-24 12:49:33'),
(104, 'PAR0104', 'yusuf', 'ishola', 1, NULL, NULL, NULL, 'yetty@gmail.com', NULL, NULL, NULL, NULL, NULL, '08034706971', NULL, 65, NULL, '2015-03-24 01:49:53', '2015-03-24 12:49:53'),
(105, 'PAR0105', 'Norbert', 'Mbaegbu', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037186709', NULL, 60, NULL, '2015-03-24 01:51:28', '2015-03-24 12:51:28'),
(106, 'PAR0106', 'Joseph', 'madueke', 1, NULL, NULL, NULL, 'madson1993@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033012374', NULL, 65, NULL, '2015-03-24 01:51:34', '2015-03-24 12:51:34'),
(107, 'PAR0107', 'ayodele', 'odufuwa', 1, NULL, NULL, NULL, 'odufuwdupe@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08055476213', NULL, 65, NULL, '2015-03-24 01:54:29', '2015-03-24 12:54:30'),
(108, 'PAR0108', 'p.a', 'olaniyan', 1, 'tt', '', '', 'akinolaniyanpms@yahoo.com', NULL, 'Hhgg', 147, 7, 140, '08033181314', '', 65, NULL, '2015-03-24 01:56:51', '2015-03-24 13:22:55'),
(109, 'PAR0109', 'Matthew', 'olory', 1, NULL, NULL, NULL, '0806666811', NULL, NULL, NULL, NULL, NULL, '08037865675', NULL, 65, NULL, '2015-03-24 02:00:01', '2015-03-24 13:00:01'),
(110, 'PAR0110', 'Emmanuel', 'Tobiah', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037950435', NULL, 43, NULL, '2015-03-24 02:00:32', '2015-03-24 13:00:32'),
(111, 'PAR0111', 'Matthew', 'olory', 1, NULL, NULL, NULL, 'matthewolory@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08066666811', NULL, 65, NULL, '2015-03-24 02:01:04', '2015-03-24 13:01:04'),
(112, 'PAR0112', 'Matthew', 'oneh', 1, NULL, NULL, NULL, 'm.oneh@interairnigeria.com', NULL, NULL, NULL, NULL, NULL, '08037865676', NULL, 65, NULL, '2015-03-24 02:06:06', '2015-03-24 13:06:06'),
(113, 'PAR0113', 'Isiaka', 'Oke', 11, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08090906406', NULL, 44, NULL, '2015-03-24 02:11:48', '2015-03-24 13:11:48'),
(114, 'PAR0114', 'nkereuwem', 'onung', 1, NULL, NULL, NULL, 'afimaonung@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08037135661', NULL, 65, NULL, '2015-03-24 02:12:04', '2015-03-24 13:12:04'),
(115, 'PAR0115', 'Kingsley', 'osadolor', 1, NULL, NULL, NULL, 'osakingosa@hotmail.com', NULL, NULL, NULL, NULL, NULL, '08033042837', NULL, 65, NULL, '2015-03-24 02:15:02', '2015-03-24 13:15:02'),
(116, 'PAR0116', 'FAITH', 'ATABULE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08055024772', NULL, 60, NULL, '2015-03-24 02:18:25', '2015-03-24 13:18:26'),
(117, 'PAR0117', 'OLAMIDE', 'KUSHIMOH', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08054881234', NULL, 60, NULL, '2015-03-24 02:19:05', '2015-03-24 13:19:05'),
(119, 'PAR0119', 'MOTUNRAYO', 'OGUNDIMU', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08050442115', NULL, 60, NULL, '2015-03-24 02:21:29', '2015-03-24 13:21:29'),
(120, 'PAR0120', 'HAUWA', 'BUHARI-ABDULLAHI', 11, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033024367', NULL, 60, NULL, '2015-03-24 02:22:41', '2015-03-24 13:22:41'),
(121, 'PAR0121', 'Ayomide', 'Faloye', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033040696', NULL, 43, NULL, '2015-03-24 02:22:59', '2015-03-24 13:22:59'),
(122, 'PAR0122', 'ENIOLA', 'LAWAL', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033370213', NULL, 60, NULL, '2015-03-24 02:24:32', '2015-03-24 13:24:32'),
(123, 'PAR0123', 'Tomisin', 'Asubiaro', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08030839881', NULL, 13, NULL, '2015-03-24 02:24:51', '2015-03-24 13:24:51'),
(124, 'PAR0124', 'okey', 'ibeke', 1, NULL, NULL, NULL, 'bekey4all@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033040009', NULL, 65, NULL, '2015-03-24 02:25:03', '2015-03-24 13:25:03'),
(125, 'PAR0125', 'EMILY', 'ITSEUWA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033215262', NULL, 60, NULL, '2015-03-24 02:26:10', '2015-03-24 13:26:10'),
(126, 'PAR0126', 'OLUWAFUNMILAYO', 'OSHOBU', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023039969', NULL, 60, NULL, '2015-03-24 02:27:47', '2015-03-24 13:27:47'),
(127, 'PAR0127', 'OLUWASEUN', 'SANNI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023187676', NULL, 60, NULL, '2015-03-24 02:28:52', '2015-03-24 13:28:53'),
(128, 'PAR0128', 'JENNIFER', 'ONYEMAECHI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033088494', NULL, 60, NULL, '2015-03-24 02:29:56', '2015-03-24 13:29:56'),
(129, 'PAR0129', 'RUKEVWE', 'ERIVWODE ', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08066766565', NULL, 60, NULL, '2015-03-24 02:31:00', '2015-03-24 13:31:01'),
(130, 'PAR0130', 'HABEEBAT', 'LAWAL', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033379127', NULL, 60, NULL, '2015-03-24 02:32:03', '2015-03-24 13:32:03'),
(131, 'PAR0131', 'IBUKUN', 'POPOOLA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07085810372', NULL, 60, NULL, '2015-03-24 02:32:59', '2015-03-24 13:32:59'),
(132, 'PAR0132', 'OLUWATOMIWA', 'NOIKI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023092160', NULL, 60, NULL, '2015-03-24 02:33:52', '2015-03-24 13:33:53'),
(133, 'PAR0133', 'SOMKENE', 'EZEJELUE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037278502', NULL, 60, NULL, '2015-03-24 02:34:55', '2015-03-24 13:34:55'),
(134, 'PAR0134', 'Kayode', 'Faluade', 1, NULL, NULL, NULL, 'Kayodefaluade@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08023361524', NULL, 50, NULL, '2015-03-24 02:48:18', '2015-03-24 13:48:18'),
(135, 'PAR0135', 'Ogheneyoma', 'Hamman-Obel', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08026806660', NULL, 43, NULL, '2015-03-24 02:48:23', '2015-03-24 13:48:24'),
(136, 'PAR0136', 'Ibrahim', 'Akintola', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033049351', NULL, 50, NULL, '2015-03-24 02:50:38', '2015-03-24 13:50:38'),
(137, 'PAR0137', 'Adetunji', 'Hassan', 1, NULL, NULL, NULL, 'Hassankhadijan@gmail.com', NULL, NULL, NULL, NULL, NULL, '08055463880', NULL, 50, NULL, '2015-03-24 02:52:09', '2015-03-24 13:52:09'),
(138, 'PAR0138', 'Victor', 'Okesina', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08062883453', NULL, 50, NULL, '2015-03-24 02:53:42', '2015-03-24 13:53:42'),
(139, 'PAR0139', 'Adeyinka', 'Adeniyi', 1, NULL, NULL, NULL, 'ontop.affairs@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08029727676', NULL, 50, NULL, '2015-03-24 02:54:59', '2015-03-24 13:55:00'),
(141, 'PAR0141', 'Adekunle', 'Adesina', 1, NULL, NULL, NULL, 'Adekunle.adesina@gmail.com', NULL, NULL, NULL, NULL, NULL, '08034722758', NULL, 50, NULL, '2015-03-24 02:59:11', '2015-03-24 13:59:11'),
(142, 'PAR0142', 'Olukayode', 'Agunbiade', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07031193987', NULL, 50, NULL, '2015-03-24 03:03:38', '2015-03-24 14:03:38'),
(143, 'PAR0143', 'Hope', 'Chinda', 1, NULL, NULL, NULL, 'Adekokun2@hotmail.com', NULL, NULL, NULL, NULL, NULL, '08023335056', NULL, 50, NULL, '2015-03-24 03:04:50', '2015-03-24 14:04:50'),
(144, 'PAR0144', 'Olufemi', 'Samson', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08168442659', NULL, 50, NULL, '2015-03-24 03:06:43', '2015-03-24 14:06:43'),
(145, 'PAR0145', 'AMOUDATH', 'ABDOU', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '22997222403', NULL, 60, NULL, '2015-03-24 03:08:15', '2015-03-24 18:43:11'),
(146, 'PAR0146', 'BABAJIDE', 'BAKRE', 1, NULL, NULL, NULL, 'jidebakre@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033076087', NULL, 13, NULL, '2015-03-24 03:13:57', '2015-03-25 15:39:27'),
(147, 'PAR0147', 'Williams', 'chiejile', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08051245920', NULL, 13, NULL, '2015-03-24 03:14:55', '2015-03-24 14:14:55'),
(148, 'PAR0148', 'Sunkanmi', 'Lawal', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033370213', NULL, 13, NULL, '2015-03-24 03:15:30', '2015-03-24 14:15:30'),
(149, 'PAR0149', 'Victor', 'Nwogu', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '0803397834', NULL, 13, NULL, '2015-03-24 03:16:18', '2015-03-24 14:16:19'),
(150, 'PAR0150', 'Chigozie', 'Okeke ', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032463769', NULL, 13, NULL, '2015-03-24 03:16:55', '2015-03-24 14:16:56'),
(151, 'PAR0151', 'Timilehin', 'Ogunbanjo', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033058040', NULL, 13, NULL, '2015-03-24 03:17:35', '2015-03-24 14:17:36'),
(152, 'PAR0152', 'Christian', 'Onwuchelu ', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '22505052049', NULL, 13, NULL, '2015-03-24 03:18:41', '2015-03-24 14:18:42'),
(153, 'PAR0153', 'Oluwaseun', 'Soyebi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08060854491', NULL, 13, NULL, '2015-03-24 03:19:19', '2015-03-24 14:19:20'),
(154, 'PAR0154', 'Chibueze', 'Uduji-Emenike', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033283134', NULL, 13, NULL, '2015-03-24 03:20:06', '2015-03-24 14:20:06'),
(155, 'PAR0155', 'Olaoluwa', 'Olatunbosun', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08028723456', NULL, 13, NULL, '2015-03-24 03:21:08', '2015-03-24 14:21:08'),
(156, 'PAR0156', 'Felix', 'Ikpi-Iyam', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033131070', NULL, 13, NULL, '2015-03-24 03:21:53', '2015-03-24 14:21:53'),
(158, 'PAR0158', 'OLAWALE', 'KAZEEM', 11, NULL, NULL, NULL, 'Kazwal2@yahoo.com', NULL, NULL, NULL, NULL, NULL, '018907218', NULL, 60, NULL, '2015-03-24 03:38:18', '2015-03-24 14:38:19'),
(159, 'PAR0159', 'CHRISTINA', 'UGOCHUKWU', 4, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08034027185', NULL, 60, NULL, '2015-03-24 03:44:20', '2015-03-24 14:44:20'),
(160, 'PAR0160', 'BABAFEMI ', 'OJUDU', 1, NULL, NULL, NULL, 'ojudubabafemi@gmail.com', NULL, NULL, NULL, NULL, NULL, '08023033594', NULL, 60, NULL, '2015-03-24 03:52:35', '2015-03-24 14:52:35'),
(161, 'PAR0161', 'wuraola', 'Afolabi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07062845703', NULL, 23, NULL, '2015-03-24 03:55:54', '2015-03-24 14:55:55'),
(162, 'PAR0162', 'EMMANUEL', 'Angel', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032185524', NULL, 23, NULL, '2015-03-24 03:56:54', '2015-03-24 14:56:54'),
(163, 'PAR0163', 'Irene', 'Ikpi-Iyam', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033131070', NULL, 23, NULL, '2015-03-24 03:58:14', '2015-03-24 14:58:14'),
(164, 'PAR0164', 'Precious', 'Johnson', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08026621330', NULL, 23, NULL, '2015-03-24 03:59:31', '2015-03-24 14:59:31'),
(165, 'PAR0165', 'Viola', 'Okey-Ezealah', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08055288380', NULL, 23, NULL, '2015-03-24 04:02:07', '2015-03-24 15:02:07'),
(166, 'PAR0166', 'Yemisi', 'Oshobu', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023164370', NULL, 23, NULL, '2015-03-24 04:03:30', '2015-03-24 15:03:31'),
(168, 'PAR0168', 'Anike', 'Sobowale', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037235348', NULL, 23, NULL, '2015-03-24 04:05:42', '2015-03-24 15:05:42'),
(169, 'PAR0169', 'Mariam', 'Yahaya', 11, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033045008', NULL, 23, NULL, '2015-03-24 04:06:59', '2015-03-24 15:06:59'),
(170, 'PAR0170', 'RAJEEV', 'DANDEKAR', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08024780331', NULL, 62, NULL, '2015-03-24 04:09:02', '2015-03-24 15:09:02'),
(171, 'PAR0171', 'KENNEDY', 'ONONAEKE', 5, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08056316263', NULL, 62, NULL, '2015-03-24 04:10:28', '2015-03-24 15:10:28'),
(172, 'PAR0172', 'PETER PAUL', 'ANAGBE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08062100389', NULL, 62, NULL, '2015-03-24 04:12:03', '2015-03-24 15:12:04'),
(173, 'PAR0173', 'OLALEKAN', 'ALAYANDE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08036158009', NULL, 62, NULL, '2015-03-24 04:13:06', '2015-03-24 15:13:06'),
(174, 'PAR0174', 'MUFTAU', 'OYENIRAN', 11, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08024401482', NULL, 62, NULL, '2015-03-24 04:13:52', '2015-03-24 15:13:52'),
(178, 'PAR0178', 'Adediran', 'Olukokun', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023335056', NULL, 50, NULL, '2015-03-24 04:24:32', '2015-03-24 15:24:32'),
(179, 'PAR0179', 'ADEBAYO', 'AKINTELU', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07034154821', NULL, 62, NULL, '2015-03-24 04:27:11', '2015-03-24 15:27:11'),
(180, 'PAR0180', 'ADEPOJU', 'LAWRENCE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023031469', NULL, 62, NULL, '2015-03-24 04:35:02', '2015-03-24 15:35:02'),
(181, 'PAR0181', 'HAFEEZ', 'ABIOLA', 1, NULL, NULL, NULL, 'habiola@elektrint.com', NULL, NULL, NULL, NULL, NULL, '08033065549', NULL, 16, NULL, '2015-03-24 04:35:06', '2015-03-24 15:35:07'),
(182, 'PAR0182', 'ADEOSUN', 'OLADAPO', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033463008', NULL, 62, NULL, '2015-03-24 04:36:05', '2015-03-24 15:36:06'),
(183, 'PAR0183', 'ABDULSALAM ', 'ADENIYI', 1, NULL, NULL, NULL, 'wallayadeniyi@yahoo.co.uk', NULL, NULL, NULL, NULL, NULL, '08033142881', NULL, 16, NULL, '2015-03-24 04:37:02', '2015-03-24 15:37:03'),
(184, 'PAR0184', 'BELLO', 'UBANDOMA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032260898', NULL, 62, NULL, '2015-03-24 04:37:47', '2015-03-24 15:37:47'),
(185, 'PAR0185', 'ISLAM', 'AJIBOLA', 1, NULL, NULL, NULL, 'tempuston@yahoo.com', NULL, NULL, NULL, NULL, NULL, '07061376488', NULL, 16, NULL, '2015-03-24 04:38:16', '2015-03-24 15:38:16'),
(186, 'PAR0186', 'OLUDAYO', 'BAKARE', 1, NULL, NULL, NULL, 'Rafiu.Bakare@zenithbank.com', NULL, NULL, NULL, NULL, NULL, '08033087642', NULL, 16, NULL, '2015-03-24 04:39:18', '2015-03-24 15:39:18'),
(188, 'PAR0188', 'AYOTUNDE', 'BELLO ', 1, NULL, NULL, NULL, 'bello_topza@yahoo.co.uk', NULL, NULL, NULL, NULL, NULL, '08055832217', NULL, 16, NULL, '2015-03-24 04:40:26', '2015-03-24 15:40:26'),
(189, 'PAR0189', 'OBINNA', 'EMMANUEL', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032185524', NULL, 16, NULL, '2015-03-24 04:41:32', '2015-03-24 15:41:32'),
(190, 'PAR0190', 'IYIOLA', 'FOLORUNSO', 1, NULL, NULL, NULL, 'isaac.folorunso@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08023120561', NULL, 16, NULL, '2015-03-24 04:43:05', '2015-03-24 15:43:05'),
(191, 'PAR0191', 'OLUWABUKUNMI', 'IDOWU', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033034118', NULL, 16, NULL, '2015-03-24 04:44:17', '2015-03-24 15:44:17'),
(192, 'PAR0192', 'OMAGBITSE', 'NIKORO', 1, NULL, NULL, NULL, 'tonynikoro@yahoo.co.uk', NULL, NULL, NULL, NULL, NULL, '08051095262', NULL, 16, NULL, '2015-03-24 04:45:18', '2015-03-24 15:45:19'),
(193, 'PAR0193', 'I', 'FAYOMI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08035070732', NULL, 62, NULL, '2015-03-24 04:45:48', '2015-03-24 15:45:49'),
(194, 'PAR0194', 'SAMSON', 'OBRIBAI', 1, NULL, NULL, NULL, 'yeyeone@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08038266225', NULL, 16, NULL, '2015-03-24 04:46:23', '2015-03-24 15:46:23'),
(195, 'PAR0195', 'CHURCHIL', 'ELENDU', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08034740241', NULL, 62, NULL, '2015-03-24 04:46:53', '2015-03-24 15:46:53'),
(196, 'PAR0196', 'MOBOLUWADURO', 'OGUNDIMU ', 1, NULL, NULL, NULL, 'sina_ogun@yahoo.co.uk', NULL, NULL, NULL, NULL, NULL, '08037224353', NULL, 16, NULL, '2015-03-24 04:47:24', '2015-03-24 15:47:24'),
(198, 'PAR0198', 'AYOOLA', 'OGUNEKO', 1, NULL, NULL, NULL, 'oguneko.o@acn.aero', NULL, NULL, NULL, NULL, NULL, '08034061274', NULL, 16, NULL, '2015-03-24 04:48:52', '2015-03-24 15:48:52'),
(199, 'PAR0199', 'PAUL', 'OKOYE ', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032235812', NULL, 16, NULL, '2015-03-24 04:49:29', '2015-03-24 15:49:29'),
(200, 'PAR0200', 'NATHANIEL', 'OKPARA', 1, NULL, NULL, NULL, 'daniel.okpara@qualitymarineng.com', NULL, NULL, NULL, NULL, NULL, '08034345521', NULL, 16, NULL, '2015-03-24 04:50:29', '2015-03-24 15:50:29'),
(201, 'PAR0201', 'AYOTOMI ', 'SOWOLE', 1, NULL, NULL, NULL, 'sowoles@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08035942511', NULL, 16, NULL, '2015-03-24 04:51:28', '2015-03-24 15:51:28'),
(204, 'PAR0204', 'ABAYOMI', 'SOGE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08024700738', NULL, 62, NULL, '2015-03-24 06:55:11', '2015-03-24 17:55:11'),
(205, 'PAR0205', 'HABEEB', 'RAJI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08026301862', NULL, 62, NULL, '2015-03-24 06:58:45', '2015-03-24 17:58:45'),
(206, 'PAR0206', 'OLANREWAJU', 'OSINAIKE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033212239', NULL, 62, NULL, '2015-03-24 07:04:54', '2015-03-24 18:04:54'),
(207, 'PAR0207', 'YAYA', 'AMZAT', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07074969994', NULL, 62, NULL, '2015-03-24 07:08:01', '2015-03-24 18:08:01'),
(208, 'PAR0208', 'Olumuyiwa', 'Soge', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08036661699', NULL, 40, NULL, '2015-03-25 08:12:08', '2015-03-25 07:12:08'),
(209, 'PAR0209', 'Hani', 'Shadouh', 8, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08039567889', NULL, 40, NULL, '2015-03-25 08:15:40', '2015-03-25 07:15:40'),
(210, 'PAR0210', 'Adeniyi', 'Ibazebo', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08094649847', NULL, 40, NULL, '2015-03-25 08:17:47', '2015-03-25 07:17:47'),
(211, 'PAR0211', 'Olusayo', 'Ajisebutu', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08052155846', NULL, 40, NULL, '2015-03-25 08:20:41', '2015-03-25 07:20:41'),
(212, 'PAR0212', 'Yisa', 'Oshunlola', 11, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033436172', NULL, 40, NULL, '2015-03-25 08:21:29', '2015-03-25 07:21:29'),
(213, 'PAR0213', 'Oludare', 'Olaore', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08055257545', NULL, 40, NULL, '2015-03-25 08:22:43', '2015-03-25 07:22:43'),
(214, 'PAR0214', 'Tunde', 'Olasedidun', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08065058550', NULL, 40, NULL, '2015-03-25 08:26:32', '2015-03-25 07:26:32'),
(215, 'PAR0215', 'Lawrence', 'Adepoju', 7, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023031469', NULL, 40, NULL, '2015-03-25 08:28:22', '2015-03-25 07:28:22'),
(216, 'PAR0216', 'Emeka', 'Onwuchelu', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '05052049', NULL, 43, NULL, '2015-03-25 09:13:15', '2015-03-25 08:13:15'),
(217, 'PAR0217', 'Bolaji', 'Ishola', 1, NULL, NULL, NULL, 'adeoluwafaniyi@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08023409352', NULL, 43, NULL, '2015-03-25 09:19:24', '2015-03-25 08:19:24'),
(218, 'PAR0218', 'Paul', 'Akpama', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07062849533', NULL, 43, NULL, '2015-03-25 09:23:02', '2015-03-25 08:23:02'),
(219, 'PAR0219', 'John', 'Wikimor', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08052462012', NULL, 43, NULL, '2015-03-25 09:25:44', '2015-03-25 08:25:44'),
(220, 'PAR0220', 'Ebikabo-Owei', 'Ziworitin', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07036603754', NULL, 43, NULL, '2015-03-25 09:30:26', '2015-03-25 08:30:27'),
(221, 'PAR0221', 'Anthony', 'Olumese', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07098702770', NULL, 38, NULL, '2015-03-25 09:31:19', '2015-03-25 08:31:19'),
(222, 'PAR0222', 'Abraham', 'Markbere', 2, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07030952769', NULL, 43, NULL, '2015-03-25 09:33:05', '2015-03-25 08:33:05'),
(223, 'PAR0223', 'Ifeanyi', 'Okunbor', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08034029238', NULL, 38, NULL, '2015-03-25 09:34:37', '2015-03-25 08:34:37'),
(224, 'PAR0224', 'Oluwafemi', 'Osinbanjo', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033223660', NULL, 38, NULL, '2015-03-25 09:35:20', '2015-03-25 08:35:21'),
(225, 'PAR0225', 'Adekunle', 'Awolaja', 1, NULL, NULL, NULL, 'kunlaj2002@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08053021329', NULL, 38, NULL, '2015-03-25 09:35:58', '2015-03-25 14:05:56'),
(226, 'PAR0226', 'Fatou', 'Abdou', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '+22990927584', NULL, 38, NULL, '2015-03-25 09:37:01', '2015-03-25 08:37:01'),
(227, 'PAR0227', 'Offodile', 'Emmanuel', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032185524', NULL, 38, NULL, '2015-03-25 09:38:02', '2015-03-25 08:38:02'),
(228, 'PAR0228', 'Michael', 'Ohadike', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023003470', NULL, 38, NULL, '2015-03-25 09:38:40', '2015-03-25 08:38:40'),
(229, 'PAR0229', 'Okechukwu', 'Owhonda', 7, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023119504', NULL, 38, NULL, '2015-03-25 09:39:32', '2015-03-25 08:39:32'),
(230, 'PAR0230', 'Layefa', 'Eldine', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037794556', NULL, 43, NULL, '2015-03-25 09:41:57', '2015-03-25 08:41:57'),
(231, 'PAR0231', 'Simolings', 'Simolings', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08024685146', NULL, 43, NULL, '2015-03-25 09:45:43', '2015-03-25 08:45:43'),
(232, 'PAR0232', 'Peter', 'Anagbe', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08062100829', NULL, 54, NULL, '2015-03-25 09:51:13', '2015-03-25 08:51:13'),
(233, 'PAR0233', 'Afolabi', 'Akinola', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '+447404659884', NULL, 54, NULL, '2015-03-25 09:51:59', '2015-03-25 08:51:59'),
(234, 'PAR0234', 'Amos', 'Shadrack', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08057340467', NULL, 43, NULL, '2015-03-25 09:53:48', '2015-03-25 08:53:48'),
(235, 'PAR0235', 'Adebisi', 'Gbadebo', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07062786208', NULL, 54, NULL, '2015-03-25 09:54:00', '2015-03-25 08:54:00'),
(236, 'PAR0236', 'Najeem', 'Ogundeyi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032380610', NULL, 54, NULL, '2015-03-25 09:55:34', '2015-03-25 08:55:35'),
(237, 'PAR0237', 'Ismael', 'Ogunbona', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033244810', NULL, 54, NULL, '2015-03-25 09:57:57', '2015-03-25 08:57:58'),
(238, 'PAR0238', 'Adeniran', 'Olukokun', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023335056', NULL, 54, NULL, '2015-03-25 10:04:05', '2015-03-25 09:04:05'),
(239, 'PAR0239', 'Oluwagbenga', 'Ojo', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033436172', NULL, 54, NULL, '2015-03-25 10:04:48', '2015-03-25 09:04:48'),
(240, 'PAR0240', 'Habeeb', 'Raji', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023335273', NULL, 54, NULL, '2015-03-25 10:05:33', '2015-03-25 09:05:33'),
(241, 'PAR0241', 'Rotimi', 'Adeola', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08055154675', NULL, 54, NULL, '2015-03-25 10:06:21', '2015-03-25 09:06:21'),
(242, 'PAR0242', 'James', 'Oyedeji', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08026819964', NULL, 54, NULL, '2015-03-25 10:07:28', '2015-03-25 09:07:28'),
(243, 'PAR0243', 'Joel', 'Promise', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08068050905', NULL, 43, NULL, '2015-03-25 10:08:33', '2015-03-25 09:08:34'),
(244, 'PAR0244', 'Ebiye', 'Agadah', 1, NULL, NULL, NULL, 'chairman.bssb.gov.com', NULL, NULL, NULL, NULL, NULL, '07062522236', NULL, 43, NULL, '2015-03-25 10:35:52', '2015-03-25 09:35:52'),
(246, 'PAR0246', 'Ayere', 'Jesumienpreder', 1, NULL, NULL, NULL, 'chairman.bssb@gmail.com', NULL, NULL, NULL, NULL, NULL, '07062522236', NULL, 43, NULL, '2015-03-25 10:41:43', '2015-03-25 09:41:44'),
(247, 'PAR0247', 'Emmanuel', 'DANIEL', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08152662481', NULL, 43, NULL, '2015-03-25 11:35:25', '2015-03-25 10:35:25'),
(248, 'PAR0248', 'Glory', 'Akunwa', 1, 'Property Developer', 'Glomykes Property Development Co. Ltd.', '', 'glomyke@yahoo.com', NULL, 'D46, Royal Gardens Estate, Ajah - Lekki, Lagos.', 188, 9, 140, '08023020139', '08025191010', 42, NULL, '2015-03-25 12:44:02', '2015-03-25 19:21:50'),
(249, 'PAR0249', 'Obioma', 'Anokwuru', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023121077', NULL, 42, NULL, '2015-03-25 12:46:14', '2015-03-25 11:46:14'),
(251, 'PAR0251', 'Garba', 'Bello', 1, NULL, NULL, NULL, 'gbkankarofi@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08023240911', NULL, 42, NULL, '2015-03-25 12:50:12', '2015-03-25 11:50:12'),
(252, 'PAR0252', 'David', 'DADINSON-OGBOGBO ', 1, NULL, NULL, NULL, 'tone_ventures@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08032002657', NULL, 42, NULL, '2015-03-25 12:51:49', '2015-03-25 11:51:50'),
(253, 'PAR0253', 'Guardian', 'Bayelsa', 1, NULL, NULL, NULL, 'oyinbunugha@gmail.com', NULL, NULL, NULL, NULL, NULL, '07062522236', NULL, 46, NULL, '2015-03-25 01:27:30', '2015-03-25 12:27:30'),
(254, 'PAR0254', 'FAVOUR', 'NWOKEKE', 1, NULL, NULL, NULL, 'nwokekebasil@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08032002294', NULL, 46, NULL, '2015-03-25 01:31:40', '2015-03-25 12:31:40'),
(256, 'PAR0256', 'David', 'DADINSON-OGBOGBO ', 1, NULL, NULL, NULL, 'tone_ventures@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08032002657', NULL, 42, NULL, '2015-03-25 02:01:23', '2015-03-25 13:01:23'),
(257, 'PAR0257', 'Owabomate', 'DAPPAH ', 1, NULL, NULL, NULL, 'dappaizrael@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08024379053', NULL, 42, NULL, '2015-03-25 02:05:07', '2015-03-25 13:05:07'),
(258, 'PAR0258', 'EBUBECHI', 'EZIMOHA ', 1, NULL, NULL, NULL, 'okechukwu.ezimoha@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033314669', NULL, 42, NULL, '2015-03-25 02:09:37', '2015-03-25 13:09:37'),
(259, 'PAR0259', 'MIRACLE', 'NNOROM', 1, NULL, NULL, NULL, 'emmanuel.nnorom@ubagroup.com', NULL, NULL, NULL, NULL, NULL, '08033034944', NULL, 42, NULL, '2015-03-25 02:18:48', '2015-03-25 13:18:48'),
(260, 'PAR0260', 'CHIDIEBUBE', 'OGBECHIE', 1, NULL, NULL, NULL, 'nyem0430@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033353232', NULL, 42, NULL, '2015-03-25 02:20:16', '2015-03-25 13:20:17'),
(261, 'PAR0261', 'EBUBE', 'OKEREAFOR', 1, NULL, NULL, NULL, 'goddyuoconcept@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08034040316', NULL, 42, NULL, '2015-03-25 02:23:04', '2015-03-25 13:23:04'),
(262, 'PAR0262', 'OLADIPO', 'OLANIYONU', 1, NULL, NULL, NULL, 'yusuphola@yahoo.co.uk', NULL, NULL, NULL, NULL, NULL, '08055001965', NULL, 42, NULL, '2015-03-25 02:25:08', '2015-03-25 13:25:08'),
(263, 'PAR0263', 'RINCHA', 'UNAH', 1, NULL, NULL, NULL, 'nwaunah@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08023232152', NULL, 42, NULL, '2015-03-25 02:33:42', '2015-03-25 13:33:42'),
(264, 'PAR0264', 'CHUKWURAH', 'IGWE', 4, NULL, NULL, NULL, 'kemfe@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033005452', NULL, 32, NULL, '2015-03-25 04:23:23', '2015-03-25 15:23:23'),
(265, 'PAR0265', 'DANIEL', 'OBIDIEGWU', 1, NULL, NULL, NULL, 'daobidiegwu@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08034788780', NULL, 32, NULL, '2015-03-25 04:24:43', '2015-03-25 15:24:43'),
(266, 'PAR0266', 'MATTHEW', 'AGBAWHE', 8, NULL, NULL, NULL, 'matty2001@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08023252981', NULL, 32, NULL, '2015-03-25 04:27:08', '2015-03-25 15:27:08'),
(267, 'PAR0267', 'ALEX', 'ASAKITIPI', 1, NULL, NULL, NULL, 'alexasak@yahoo.com', NULL, NULL, NULL, NULL, NULL, '27738500581', NULL, 32, NULL, '2015-03-25 04:29:25', '2015-03-25 15:29:25'),
(268, 'PAR0268', 'KOREDE', 'ODESANYA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023014818', NULL, 59, NULL, '2015-03-25 04:47:56', '2015-03-25 15:47:57'),
(269, 'PAR0269', 'TEMILOLUWA', 'OSHINAIKE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033212239', NULL, 59, NULL, '2015-03-25 04:54:09', '2015-03-25 15:54:09'),
(270, 'PAR0270', 'YEWANDE', 'TOOGUN', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07038166337', NULL, 59, NULL, '2015-03-25 04:55:22', '2015-03-25 15:55:23'),
(271, 'PAR0271', 'JEREMIAH', 'ENI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07056058605', NULL, 59, NULL, '2015-03-25 04:57:12', '2015-03-25 15:57:13'),
(272, 'PAR0272', 'HOPE', 'OPARA', 1, NULL, NULL, NULL, 'toykachy@yahoo.com', NULL, NULL, NULL, NULL, NULL, '07029198727', NULL, 32, NULL, '2015-03-25 05:07:48', '2015-03-25 16:07:49'),
(273, 'PAR0273', 'Daaiyefumasu', 'NICHOLAS', 1, NULL, NULL, NULL, 'chairman.bssb@gmail.com', NULL, NULL, NULL, NULL, NULL, '07062522236', NULL, 43, NULL, '2015-03-26 12:22:49', '2015-03-26 11:22:49');

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
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=286 ;

--
-- Dumping data for table `students`
--

INSERT INTO `students` (`student_id`, `sponsor_id`, `first_name`, `surname`, `other_name`, `student_no`, `image_url`, `gender`, `birth_date`, `class_id`, `religion`, `previous_school`, `academic_term_id`, `term_admitted`, `student_status_id`, `local_govt_id`, `state_id`, `country_id`, `relationtype_id`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 2, 'JOSEPH', 'ADENIRAN', '', 'STD0001', NULL, 'Male', NULL, 2, NULL, NULL, 1, '', 1, 248, 36, 140, 1, 1, '2015-03-19 08:12:26', '2015-03-23 00:39:43'),
(2, 3, 'BANKOLE', 'ATUNRASE', '', 'STD0002', NULL, 'Male', NULL, 2, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 0, '2015-03-21 11:12:32', '2015-03-23 00:32:48'),
(3, 4, ' PHOS BAYOWA', 'BAIYEKUSI', '', 'STD0003', NULL, 'Male', NULL, 2, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 0, '2015-03-21 11:14:27', '2015-03-23 00:33:36'),
(4, 5, 'OLUWATOFARATI ', 'BAKRE ', 'DAVID', 'STD0004', NULL, 'Male', '2004-08-01', 2, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 0, '2015-03-21 03:34:07', '2015-03-21 15:31:08'),
(5, 6, 'MOSES', 'BALOGUN ', '', 'STD0005', NULL, 'Male', NULL, 2, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 0, '2015-03-21 03:48:50', '2015-03-23 00:30:57'),
(6, 7, 'NATHAN', 'BAYOKO ', '', 'STD0006', NULL, 'Male', NULL, 2, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 0, '2015-03-21 04:01:19', '2015-03-21 15:02:26'),
(7, 8, 'SAMUEL', 'EGBEDEYI ', '', 'STD0007', NULL, 'Male', NULL, 2, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-03-21 04:32:36', '2015-03-21 16:14:17'),
(10, 9, 'HENRY-NKEKI', ' DAVID', '', 'STD0010', NULL, 'Male', NULL, 2, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 0, '2015-03-22 04:42:07', '2015-03-22 15:42:07'),
(11, 10, 'DAVID', 'IBILOLA ', '', 'STD0011', NULL, 'Male', NULL, 2, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 0, '2015-03-22 04:42:51', '2015-03-22 15:47:44'),
(12, 16, 'JOSEPH', 'OLATUNBOSUN', 'OLANREWAJU', 'STD0012', NULL, 'Male', '2004-04-16', 2, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 0, '2015-03-23 01:01:45', '2015-03-23 00:41:56'),
(13, 17, 'YUSUF', 'AYODELE', '', 'STD0013', NULL, 'Male', NULL, 2, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 0, '2015-03-23 01:14:59', '2015-03-23 00:17:00'),
(14, 15, ' ADEYEMI', 'OLAGUNJU', '', 'STD0014', NULL, 'Male', NULL, 2, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 0, '2015-03-23 01:21:02', '2015-03-23 00:21:02'),
(15, 14, 'JOSHUA', 'OGHOORE ', '', 'STD0015', NULL, 'Male', NULL, 2, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 0, '2015-03-23 01:21:53', '2015-03-23 00:21:53'),
(16, 13, 'CHUKWUKA', 'OFOEGBUNAM ', '', 'STD0016', NULL, 'Male', NULL, 2, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 0, '2015-03-23 01:22:39', '2015-03-23 00:22:39'),
(17, 12, 'VICTOR', 'NKUME-ANYIGOR ', '', 'STD0017', NULL, 'Male', '2004-10-31', 2, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 0, '2015-03-23 01:23:50', '2015-03-23 00:36:58'),
(18, 11, 'OLANREWAJU', 'NICK-IBITOYE ', '', 'STD0018', NULL, 'Male', NULL, 2, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 0, '2015-03-23 01:26:02', '2015-03-23 00:26:02'),
(19, 25, 'Oladapo', 'Ajayi', '', 'STD0019', NULL, 'Male', NULL, 7, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 13, '2015-03-24 10:25:17', '2015-03-24 09:25:17'),
(20, 179, 'FEYISAYO', 'AKINTELU', '', 'STD0020', NULL, 'Female', NULL, 30, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 59, '2015-03-24 10:35:21', '2015-03-25 13:34:42'),
(21, 30, 'Ifeoluwa', 'ADEALU', '', 'STD0021', NULL, 'Male', '2000-03-08', 25, NULL, NULL, 1, '', 1, 558, 23, 140, 1, 40, '2015-03-24 11:17:03', '2015-03-24 11:10:11'),
(22, 32, 'KEME', 'ABADI', '', 'STD0022', NULL, 'Male', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 11:48:22', '2015-03-24 10:48:22'),
(24, 29, 'Opeyemi', 'Williams', '', 'STD0024', NULL, 'Male', '2015-03-01', 15, NULL, NULL, 1, '', 1, 572, 23, 140, 1, 53, '2015-03-24 11:49:54', '2015-03-24 11:03:16'),
(25, 46, 'Samuel', 'Otori', '', 'STD0025', NULL, 'Male', NULL, 15, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 53, '2015-03-24 11:50:56', '2015-03-24 10:50:56'),
(26, 35, 'CHIAMAKA', 'ANIWETA-NEZIANYA', '', 'STD0026', NULL, 'Male', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 11:51:29', '2015-03-24 10:51:29'),
(27, 48, 'Timilehin', 'Salau', '', 'STD0027', NULL, 'Male', NULL, 15, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 53, '2015-03-24 11:52:01', '2015-03-24 10:52:01'),
(28, 36, 'kendrah', 'Bagou', '', 'STD0028', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 11:52:45', '2015-03-24 10:52:45'),
(29, 50, 'Ezekiel', 'Adealu', '', 'STD0029', NULL, 'Male', NULL, 15, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 53, '2015-03-24 11:52:59', '2015-03-24 10:52:59'),
(30, 52, 'Inioluwa', 'Ojo', '', 'STD0030', NULL, 'Female', NULL, 15, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 53, '2015-03-24 11:53:57', '2015-03-24 10:53:57'),
(31, 37, 'OKEOGHENE', 'ERIVWODE', 'TRACY', 'STD0031', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 11:54:00', '2015-03-24 10:54:00'),
(32, 38, 'GEORGEWILL', 'AYEBANENGIYEFA', '', 'STD0032', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 11:55:02', '2015-03-24 10:55:02'),
(33, 54, 'Adeola', 'Oloyede', '', 'STD0033', NULL, 'Female', NULL, 15, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 53, '2015-03-24 11:56:03', '2015-03-24 10:56:03'),
(34, 55, 'Oyinlade', 'Abioye', '', 'STD0034', NULL, 'Female', NULL, 15, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 53, '2015-03-24 11:56:52', '2015-03-24 10:56:52'),
(35, 56, 'Susan', 'Odesola', '', 'STD0035', NULL, 'Female', NULL, 15, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 53, '2015-03-24 11:57:36', '2015-03-24 10:57:36'),
(36, 39, 'ROSEMARY', 'ITSEUWA ', 'UYHEMIE', 'STD0036', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 11:57:45', '2015-03-24 10:57:45'),
(37, 40, 'VICTORIA', 'JOB', '', 'STD0037', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 11:59:13', '2015-03-24 10:59:13'),
(38, 41, 'HAPPINESS', 'KALAYOLO', '', 'STD0038', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 12:01:15', '2015-03-24 11:01:15'),
(39, 42, 'ONISOKIE', 'MAZI', '', 'STD0039', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 12:02:35', '2015-03-24 11:02:35'),
(40, 43, 'EVELYN', 'NATHANIEL', '', 'STD0040', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 12:03:19', '2015-03-24 11:03:19'),
(41, 44, 'OYINKANSOLA', 'OBUBE', '', 'STD0041', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 12:04:43', '2015-03-24 11:04:43'),
(42, 45, 'OYINDAMOLA', 'OKE', '', 'STD0042', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 12:05:47', '2015-03-24 11:05:47'),
(43, 47, 'CHISOM', 'OKOYE', '', 'STD0043', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 12:07:01', '2015-03-24 11:07:01'),
(44, 49, 'IBEINMO', 'TELIMOYE', '', 'STD0044', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 12:08:26', '2015-03-24 11:08:26'),
(45, 51, 'ENDURANCE', 'WAIBITE', '', 'STD0045', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 12:09:15', '2015-03-24 11:09:15'),
(46, 53, 'IBUKUN', 'WILLIAMS', '', 'STD0046', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 12:10:21', '2015-03-24 11:10:21'),
(47, 34, 'EBIKABOERE', 'AMARA', '', 'STD0047', NULL, 'Female', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 30, '2015-03-24 12:15:13', '2015-03-24 11:15:13'),
(48, 57, 'FIKAYO', 'ADEOSUN', '', 'STD0048', NULL, 'Male', NULL, 10, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 52, '2015-03-24 12:26:02', '2015-03-24 11:26:02'),
(49, 58, 'MUBARAK', 'DADA', '', 'STD0049', NULL, 'Male', NULL, 10, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 52, '2015-03-24 12:28:01', '2015-03-24 11:28:01'),
(50, 59, 'ANUOLUWA', 'DOTUN', '', 'STD0050', NULL, 'Male', NULL, 10, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 52, '2015-03-24 12:29:13', '2015-03-24 11:29:13'),
(51, 60, 'DEBORAH', 'AGUNBIADE', '', 'STD0051', NULL, 'Female', NULL, 10, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 52, '2015-03-24 12:31:10', '2015-03-24 11:31:10'),
(52, 61, 'FATHIAT', 'HAMZATH', '', 'STD0052', NULL, 'Female', NULL, 10, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 52, '2015-03-24 12:32:30', '2015-03-24 11:32:30'),
(53, 62, 'BUNMI', 'LALA', '', 'STD0053', NULL, 'Female', NULL, 10, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 52, '2015-03-24 12:34:29', '2015-03-24 11:34:29'),
(54, 63, 'ADESEWA', 'OKESINA', '', 'STD0054', NULL, 'Female', NULL, 10, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 52, '2015-03-24 12:36:02', '2015-03-24 11:36:02'),
(55, 64, 'PRINCESS', 'OJO', '', 'STD0055', NULL, 'Female', NULL, 10, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 52, '2015-03-24 12:37:07', '2015-03-24 11:37:07'),
(56, 65, 'Favour', 'Ibazebo', '', 'STD0056', NULL, 'Female', NULL, 10, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 52, '2015-03-24 01:04:41', '2015-03-24 12:04:41'),
(57, 66, 'Oluwakamiye', 'Azeez', '', 'STD0057', NULL, 'Female', NULL, 4, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 14, '2015-03-24 01:06:44', '2015-03-24 12:06:44'),
(58, 67, 'Ayotomi', 'Bello', '', 'STD0058', NULL, 'Female', NULL, 4, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 14, '2015-03-24 01:08:34', '2015-03-24 12:08:34'),
(59, 68, 'Doyinsola', 'Bello', '', 'STD0059', NULL, 'Female', NULL, 4, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 14, '2015-03-24 01:09:49', '2015-03-24 12:09:49'),
(60, 69, 'Oyintari', 'Bribena', '', 'STD0060', NULL, 'Female', NULL, 4, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 14, '2015-03-24 01:11:26', '2015-03-24 12:11:26'),
(61, 74, 'Adaobi', 'Eze', '', 'STD0061', NULL, 'Female', NULL, 4, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 14, '2015-03-24 01:12:27', '2015-03-24 12:12:27'),
(62, 70, 'Eniola', 'Folorunso', '', 'STD0062', NULL, 'Female', NULL, 4, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 14, '2015-03-24 01:13:53', '2015-03-24 12:13:53'),
(63, 71, 'Deborah', 'Ogundele', '', 'STD0063', NULL, 'Female', NULL, 4, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 14, '2015-03-24 01:15:42', '2015-03-24 12:15:42'),
(64, 72, 'Bisoye', 'Olaoye', '', 'STD0064', NULL, 'Female', NULL, 4, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 14, '2015-03-24 01:16:40', '2015-03-24 12:16:40'),
(65, 73, 'Chidera', 'Onyebuchi', '', 'STD0065', NULL, 'Female', NULL, 4, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 14, '2015-03-24 01:19:11', '2015-03-24 12:19:11'),
(66, 77, 'Massimoduath', 'Abdou', '', 'STD0066', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 01:49:38', '2015-03-24 12:49:38'),
(67, 92, 'Miriam', 'Adewole', '', 'STD0067', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 01:51:30', '2015-03-24 12:51:30'),
(68, 87, 'Grace', 'Amakedi', '', 'STD0068', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 01:52:55', '2015-03-24 12:52:55'),
(69, 88, 'Dora', 'Azugha', '', 'STD0069', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 01:54:25', '2015-03-24 12:54:25'),
(70, 76, 'Sonia', 'Dede', '', 'STD0070', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 01:55:24', '2015-03-24 12:55:24'),
(71, 75, 'Ebikila', 'Ibetei', '', 'STD0071', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 01:56:23', '2015-03-24 12:56:23'),
(72, 84, 'Monica', 'Isibor', '', 'STD0072', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 01:58:13', '2015-03-24 12:58:13'),
(73, 86, 'Karina', 'Koroye', '', 'STD0073', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 02:00:56', '2015-03-24 13:00:56'),
(74, 83, 'Dameriti', 'Maddocks', '', 'STD0074', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 02:02:48', '2015-03-24 13:02:48'),
(75, 80, 'Ebilade', 'Nanakede', '', 'STD0075', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 02:03:42', '2015-03-24 13:03:42'),
(76, 78, 'Oyinkarena', 'Obireke', '', 'STD0076', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 02:05:43', '2015-03-24 13:05:43'),
(77, 113, 'Jumoke', 'Oke', '', 'STD0077', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 02:13:15', '2015-03-24 13:13:15'),
(78, 81, 'Erebeimi', 'Puragha', '', 'STD0078', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 02:15:05', '2015-03-24 13:15:05'),
(79, 95, 'Mateni', 'Sam-Micheal', '', 'STD0079', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 02:16:28', '2015-03-24 13:16:28'),
(80, 82, 'Oyinbunugha', 'Soroh', '', 'STD0080', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 02:17:23', '2015-03-24 13:17:23'),
(81, 79, 'Maryam', 'Umoru', '', 'STD0081', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 02:18:22', '2015-03-24 13:18:22'),
(82, 90, 'Haneefa', 'Usman', '', 'STD0082', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 02:20:10', '2015-03-24 13:20:10'),
(83, 85, 'Ruth', 'Zolo', '', 'STD0083', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 02:20:53', '2015-03-24 13:20:53'),
(84, 100, 'Nike', 'Isikpi', '', 'STD0084', NULL, 'Female', NULL, 13, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 44, '2015-03-24 02:23:56', '2015-03-24 13:23:56'),
(85, 89, 'Mariam', 'Abdullahi', '', 'STD0085', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:29:04', '2015-03-24 13:29:04'),
(86, 91, 'Boluwatife', 'Adeyemi', '', 'STD0086', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:29:43', '2015-03-24 13:29:43'),
(87, 266, 'Oghaleoghene', 'Agbawhe', '', 'STD0087', NULL, 'Female', '1970-01-01', 29, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 65, '2015-03-24 02:31:06', '2015-03-25 15:48:37'),
(88, 96, 'Oluwatobi', 'Ajibode', '', 'STD0088', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:31:52', '2015-03-24 13:31:52'),
(89, 98, 'Demilade', 'Faloye', '', 'STD0089', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:32:26', '2015-03-24 13:32:26'),
(90, 124, 'Eberechukwu', 'Ibeke', '', 'STD0090', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:33:05', '2015-03-24 13:33:05'),
(91, 101, 'Lauren', 'Ikeji', '', 'STD0091', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:34:08', '2015-03-24 13:34:08'),
(92, 102, 'Kehinde', 'Imasuen', '', 'STD0092', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:35:12', '2015-03-24 13:35:12'),
(93, 47, 'CHIAMAKA', 'OKOYE', '', 'STD0093', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 02:36:39', '2015-03-24 13:36:39'),
(94, 102, 'Taiwo', 'Imasuen', '', 'STD0094', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:37:32', '2015-03-24 13:37:32'),
(95, 104, 'Oluwadamilola', 'Ishola', '', 'STD0095', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:39:25', '2015-03-24 13:39:25'),
(96, 116, 'FAITH', 'ATABULE', '', 'STD0096', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 02:39:43', '2015-03-24 13:39:43'),
(97, 107, 'Adesewa', 'Odufuwa', '', 'STD0097', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:40:42', '2015-03-24 13:40:42'),
(98, 117, 'OLAMIDE', 'KUSHIMO', '', 'STD0098', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 02:41:01', '2015-03-24 13:41:01'),
(99, 106, 'Chinyere ', 'Madueke', '', 'STD0099', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:41:32', '2015-03-24 13:41:32'),
(100, 105, 'SHARON', 'MBAEGBU', '', 'STD0100', NULL, 'Female', '1970-01-01', 24, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 60, '2015-03-24 02:42:56', '2015-03-25 14:12:21'),
(101, 108, 'Oluwatoyin', 'Olaniyan', '', 'STD0101', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:43:20', '2015-03-24 13:43:20'),
(102, 119, 'MOTUNRAYO', 'OGUNDIMU', '', 'STD0102', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 02:44:12', '2015-03-24 13:44:12'),
(103, 109, 'Lerek', 'Olory', '', 'STD0103', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:44:40', '2015-03-24 13:44:40'),
(104, 120, 'HAUWA', 'BUHARI - ABDULLAHI', '', 'STD0104', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 02:45:31', '2015-03-24 13:45:31'),
(105, 112, 'Sophia', 'Oneh', '', 'STD0105', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:46:10', '2015-03-24 13:46:10'),
(106, 122, 'ENIOLA', 'LAWAL', '', 'STD0106', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 02:47:20', '2015-03-24 13:47:20'),
(107, 114, 'Joy', 'Onung', '', 'STD0107', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:47:45', '2015-03-24 13:47:45'),
(108, 115, 'Omorowa', 'Osadolor', '', 'STD0108', NULL, 'Female', NULL, 29, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 65, '2015-03-24 02:48:59', '2015-03-24 13:48:59'),
(109, 125, 'EMILY', 'ITSEUWA', '', 'STD0109', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 02:49:34', '2015-03-24 13:49:34'),
(110, 126, 'OLUWAFUNMILAYO', 'OSHOBU', '', 'STD0110', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 02:52:03', '2015-03-24 13:52:03'),
(111, 127, 'OLUWASEUN', 'SANNI', '', 'STD0111', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 02:53:36', '2015-03-24 13:53:36'),
(112, 128, 'JENNIFER', 'ONYEMAECHI', '', 'STD0112', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 02:55:19', '2015-03-24 13:55:19'),
(113, 129, 'RUKEVWE', 'ERIVWODE', '', 'STD0113', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 03:01:17', '2015-03-24 14:01:17'),
(114, 130, 'HABEEBAT', 'LAWAL', '', 'STD0114', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 03:02:21', '2015-03-24 14:02:21'),
(115, 131, 'IBUKUN', 'POPOOLA', '', 'STD0115', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 03:03:56', '2015-03-24 14:03:56'),
(116, 132, 'OLUWATOMIWA', 'NOIKI', '', 'STD0116', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 03:04:52', '2015-03-24 14:04:52'),
(117, 133, 'SOMKENE', 'EZEJELUE', '', 'STD0117', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 03:05:47', '2015-03-24 14:05:47'),
(118, 134, 'Mayokun', 'Faluade', 'Gbadegeshin', 'STD0118', NULL, 'Male', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 50, '2015-03-24 03:20:38', '2015-03-24 14:20:38'),
(119, 145, 'AMOUDATH', 'ABDOU', '', 'STD0119', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 03:21:19', '2015-03-24 14:21:19'),
(120, 123, 'Tomisin', 'Asubiaro', '', 'STD0120', NULL, 'Male', NULL, 7, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 13, '2015-03-24 03:26:21', '2015-03-24 14:26:21'),
(121, 146, 'Oluwatobi', 'Bakre', '', 'STD0121', NULL, 'Male', NULL, 7, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 13, '2015-03-24 03:27:27', '2015-03-24 14:27:27'),
(122, 147, 'Chiejile', 'Williams', '', 'STD0122', NULL, 'Male', NULL, 7, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 13, '2015-03-24 03:28:28', '2015-03-24 14:28:28'),
(123, 148, 'Sunkanmi', 'Lawal', '', 'STD0123', NULL, 'Male', NULL, 7, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 13, '2015-03-24 03:30:17', '2015-03-24 14:30:17'),
(124, 149, 'Victor', 'Nwogu', '', 'STD0124', NULL, 'Male', NULL, 7, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 13, '2015-03-24 03:31:22', '2015-03-24 14:31:22'),
(125, 150, 'chigozie', 'Okeke', '', 'STD0125', NULL, 'Male', NULL, 7, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 13, '2015-03-24 03:32:19', '2015-03-24 14:32:19'),
(126, 151, 'Timilehin', 'ogunbanjo', '', 'STD0126', NULL, 'Male', NULL, 7, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 13, '2015-03-24 03:33:54', '2015-03-24 14:33:54'),
(127, 152, 'christian', 'onwuchelu', '', 'STD0127', NULL, 'Male', NULL, 7, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 13, '2015-03-24 03:35:41', '2015-03-24 14:35:41'),
(128, 152, 'Samuel', 'onwuchelu', '', 'STD0128', NULL, 'Male', NULL, 7, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 13, '2015-03-24 03:37:43', '2015-03-24 14:37:43'),
(129, 136, 'Ibrahim', 'Akintola', 'Agboola', 'STD0129', NULL, 'Male', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 50, '2015-03-24 03:38:15', '2015-03-24 14:38:15'),
(130, 153, 'Oluwaseun', 'Soyebi', '', 'STD0130', NULL, 'Male', NULL, 7, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 13, '2015-03-24 03:38:56', '2015-03-24 14:38:56'),
(131, 137, 'Ibrahim', 'Hassan', 'Ayodeji', 'STD0131', NULL, 'Male', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 50, '2015-03-24 03:39:31', '2015-03-24 14:39:31'),
(132, 154, 'Chibueze', 'Uduji-Emenike', '', 'STD0132', NULL, 'Male', NULL, 7, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 13, '2015-03-24 03:40:05', '2015-03-24 14:40:05'),
(133, 155, 'Olaoluwa', 'Olatunbosun', '', 'STD0133', NULL, 'Male', NULL, 7, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 13, '2015-03-24 03:41:22', '2015-03-24 14:41:22'),
(134, 158, 'ZAINAB', 'KAZEEM', '', 'STD0134', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 03:41:38', '2015-03-24 14:41:38'),
(135, 156, 'Felix', 'Ikpi-Iyam', '', 'STD0135', NULL, 'Male', NULL, 7, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 13, '2015-03-24 03:42:27', '2015-03-24 14:42:27'),
(136, 159, 'CHRISTINA', 'UGOCHUKWU', '', 'STD0136', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 03:46:53', '2015-03-24 14:46:53'),
(137, 139, 'Testimony', 'Adeniyi', 'Adeseye', 'STD0137', NULL, 'Male', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 50, '2015-03-24 03:52:07', '2015-03-24 14:52:07'),
(138, 173, 'Olaoluwa', 'Alayande', 'Olalekan', 'STD0138', NULL, 'Male', '1970-01-01', 1, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 50, '2015-03-24 03:53:36', '2015-03-25 16:01:32'),
(139, 160, 'MORENIKE', 'OJUDU', '', 'STD0139', NULL, 'Female', NULL, 24, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 60, '2015-03-24 03:53:53', '2015-03-24 14:53:53'),
(140, 134, 'Babatunde', 'Faluade', 'Mayomide', 'STD0140', NULL, 'Male', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 50, '2015-03-24 03:54:46', '2015-03-24 14:54:46'),
(141, 161, 'Wuraola', 'Afolabi', '', 'STD0141', NULL, 'Female', NULL, 9, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 23, '2015-03-24 04:08:52', '2015-03-24 15:08:52'),
(142, 141, 'Mogbekeloluwa', 'Adesina', 'Christine', 'STD0142', NULL, 'Female', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 50, '2015-03-24 04:09:27', '2015-03-24 15:09:27'),
(143, 142, 'Dorcas', 'Agunbiade', '', 'STD0143', NULL, 'Female', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 50, '2015-03-24 04:11:57', '2015-03-24 15:11:57'),
(144, 178, 'Hope', 'Chinda', '', 'STD0144', NULL, 'Female', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 50, '2015-03-24 04:27:25', '2015-03-24 15:27:25'),
(145, 144, 'Oluwadamilola', 'Samson', '', 'STD0145', NULL, 'Female', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 50, '2015-03-24 04:28:37', '2015-03-24 15:28:37'),
(146, 170, 'KSHITIJ', 'DANDEKAR', '', 'STD0146', NULL, 'Male', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 04:51:56', '2015-03-24 15:51:56'),
(147, 170, 'RUTUJ', 'DANDEKAR', '', 'STD0147', NULL, 'Male', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 04:53:07', '2015-03-24 15:53:07'),
(148, 181, 'Abiola', 'Hafeez', '', 'STD0148', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 04:54:00', '2015-03-24 15:54:00'),
(149, 183, 'Abdulsalam', 'Adeniyi', '', 'STD0149', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 04:55:16', '2015-03-24 15:55:16'),
(150, 171, 'NNAEMEZIE', 'ONONAEKE', '', 'STD0150', NULL, 'Male', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 04:55:50', '2015-03-24 15:55:50'),
(151, 185, 'Islam', 'Ajibola', '', 'STD0151', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 04:56:07', '2015-03-24 15:56:07'),
(152, 186, 'Oludayo', 'Bakare', '', 'STD0152', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 04:57:00', '2015-03-24 15:57:00'),
(153, 188, 'Ayotunde', 'Bello', '', 'STD0153', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 04:58:10', '2015-03-24 15:58:10'),
(154, 172, 'PHILLIPS', 'ANAGBE', 'SIMPA', 'STD0154', NULL, 'Male', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 04:58:36', '2015-03-24 15:58:36'),
(155, 189, 'Obinna', 'Emmanuel', '', 'STD0155', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 04:59:20', '2015-03-24 15:59:20'),
(156, 190, 'Iyiola', 'Folorunso', '', 'STD0156', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 05:01:06', '2015-03-24 16:01:06'),
(157, 191, 'Oluwabukunmi', 'Idowu', '', 'STD0157', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 05:02:15', '2015-03-24 16:02:15'),
(158, 173, 'OLAJIDE', 'ALAYANDE', 'OLUSEGUN', 'STD0158', NULL, 'Male', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 05:02:56', '2015-03-24 16:02:56'),
(159, 174, 'ABDULRASAK', 'OYENIRAN', '', 'STD0159', NULL, 'Male', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 05:05:17', '2015-03-24 16:05:17'),
(160, 192, 'Omagbitse', 'Nikoro', '', 'STD0160', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 05:05:55', '2015-03-24 16:05:55'),
(161, 194, 'Samson', 'Obribai', '', 'STD0161', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 05:06:47', '2015-03-24 16:06:47'),
(162, 196, 'Moboluwaduro', 'Ogundimu', '', 'STD0162', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 05:08:08', '2015-03-24 16:08:08'),
(163, 198, 'Ayoola', 'Oguneko', '', 'STD0163', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 05:08:58', '2015-03-24 16:08:58'),
(164, 199, 'Paul', 'Okoye', '', 'STD0164', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 05:09:38', '2015-03-24 16:09:38'),
(165, 200, 'Nathaniel', 'Okpara', '', 'STD0165', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 05:10:41', '2015-03-24 16:10:41'),
(166, 201, 'Ayotomi', 'Sowole', '', 'STD0166', NULL, 'Male', NULL, 27, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 16, '2015-03-24 05:12:18', '2015-03-24 16:12:18'),
(167, 179, 'AKINTELU', 'MOFIYINFOLUWA', '', 'STD0167', NULL, 'Female', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 05:19:07', '2015-03-24 16:19:07'),
(168, 180, 'ADESHEWA', 'LAW-ADEPOJU', '', 'STD0168', NULL, 'Female', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 05:23:25', '2015-03-24 16:23:25'),
(169, 57, 'OLUWAFISOLAMI', 'ADEOSUN', '', 'STD0169', NULL, 'Female', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 05:26:12', '2015-03-24 16:26:12'),
(170, 184, 'SAIDU', 'UBANDOMA', '', 'STD0170', NULL, 'Male', '2015-05-03', 20, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 62, '2015-03-24 05:30:17', '2015-03-25 21:10:56'),
(172, 141, 'OLUWATOMISIN', 'ADESINA', '', 'STD0172', NULL, 'Female', '1970-01-01', 20, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 62, '2015-03-24 05:37:42', '2015-03-24 18:23:11'),
(173, 193, 'OLUWATOMILOLA', 'FAYOMI', '', 'STD0173', NULL, 'Female', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 05:40:13', '2015-03-24 16:40:13'),
(174, 195, 'MERCY', 'ELENDU', '', 'STD0174', NULL, 'Female', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 05:41:49', '2015-03-24 16:41:49'),
(176, 204, 'ABISOLA', 'SOGE', 'OLAMIDE', 'STD0176', NULL, 'Female', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 06:56:26', '2015-03-24 17:56:26'),
(177, 205, 'HABEEBAT', 'RAJI', 'OMOLABALE', 'STD0177', NULL, 'Female', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 07:01:40', '2015-03-24 18:01:40'),
(178, 206, 'TEMITAYO', 'OSINAIKE', 'AYOMIDE', 'STD0178', NULL, 'Female', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 07:06:07', '2015-03-24 18:06:07'),
(179, 207, 'SOLIAT', 'HAMZAT', 'ABIOLA', 'STD0179', NULL, 'Female', NULL, 20, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 62, '2015-03-24 07:11:23', '2015-03-24 18:11:23'),
(180, 208, 'Olanrewaju', 'Soge', '', 'STD0180', NULL, 'Male', NULL, 25, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 40, '2015-03-25 08:37:34', '2015-03-25 07:37:34'),
(181, 209, 'Sammy', 'Shadouh', '', 'STD0181', NULL, 'Male', NULL, 25, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 40, '2015-03-25 08:38:47', '2015-03-25 07:38:47'),
(182, 210, 'Kelvin', 'Ibazebo', '', 'STD0182', NULL, 'Male', NULL, 25, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 40, '2015-03-25 08:39:39', '2015-03-25 07:39:39'),
(183, 211, 'Odunayo', 'Ajisebutu', '', 'STD0183', NULL, 'Male', NULL, 25, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 40, '2015-03-25 08:41:14', '2015-03-25 07:41:14'),
(184, 212, 'Boluwatife', 'Oshunlola', '', 'STD0184', NULL, 'Female', NULL, 25, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 40, '2015-03-25 08:42:16', '2015-03-25 07:42:16'),
(185, 213, 'Enitan', 'Olaore', '', 'STD0185', NULL, 'Female', NULL, 25, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 40, '2015-03-25 08:43:34', '2015-03-25 07:43:34'),
(186, 195, 'Jane', 'Elendu', '', 'STD0186', NULL, 'Female', NULL, 25, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 40, '2015-03-25 08:45:11', '2015-03-25 07:45:11'),
(187, 214, 'Ayobami', 'Olasedidun', '', 'STD0187', NULL, 'Male', NULL, 25, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 40, '2015-03-25 09:24:24', '2015-03-25 08:24:24'),
(188, 215, 'Inumidun', 'Adepoju', '', 'STD0188', NULL, 'Female', NULL, 25, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 40, '2015-03-25 09:26:01', '2015-03-25 08:26:01'),
(189, 226, 'Faissolath', 'Abdou', '', 'STD0189', NULL, 'Female', NULL, 19, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 38, '2015-03-25 09:41:25', '2015-03-25 08:41:25'),
(190, 225, 'Opemipo', 'Awolaja', '', 'STD0190', NULL, 'Female', NULL, 19, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 38, '2015-03-25 09:42:23', '2015-03-25 08:42:23'),
(191, 227, 'Chinelo', 'Emmanuel', '', 'STD0191', NULL, 'Female', NULL, 19, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 38, '2015-03-25 09:43:46', '2015-03-25 08:43:46'),
(192, 228, 'Mitchelle', 'Ohadike', '', 'STD0192', NULL, 'Female', NULL, 19, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 38, '2015-03-25 09:44:50', '2015-03-25 08:44:50'),
(193, 228, 'Oreoluwa', 'Ohadike', '', 'STD0193', NULL, 'Female', NULL, 19, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 38, '2015-03-25 09:46:20', '2015-03-25 08:46:20'),
(194, 223, 'Isioma', 'Okunbor', '', 'STD0194', NULL, 'Female', NULL, 19, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 38, '2015-03-25 09:47:00', '2015-03-25 08:47:00'),
(195, 221, 'Victory', 'Olumese', '', 'STD0195', NULL, 'Female', NULL, 19, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 38, '2015-03-25 09:47:33', '2015-03-25 08:47:33'),
(196, 224, 'Taiwo', 'Osinbanjo', '', 'STD0196', NULL, 'Female', NULL, 19, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 38, '2015-03-25 09:48:19', '2015-03-25 08:48:19'),
(197, 172, 'Serena', 'Anagbe', '', 'STD0197', NULL, 'Female', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 54, '2015-03-25 10:18:19', '2015-03-25 09:18:19'),
(198, 233, 'Richard', 'Akinola', '', 'STD0198', NULL, 'Male', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 54, '2015-03-25 10:38:31', '2015-03-25 09:38:31'),
(199, 235, 'Boluwatife', 'Gbadebo', '', 'STD0199', NULL, 'Female', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 54, '2015-03-25 10:39:37', '2015-03-25 09:39:37'),
(200, 236, 'Nofisat', 'Ogundeyi', '', 'STD0200', NULL, 'Female', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 54, '2015-03-25 10:42:03', '2015-03-25 09:42:03'),
(201, 237, 'Habeeb', 'Ogunbona', '', 'STD0201', NULL, 'Male', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 54, '2015-03-25 10:43:34', '2015-03-25 09:43:34'),
(202, 238, 'Seyi', 'Olukokun', '', 'STD0202', NULL, 'Male', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 54, '2015-03-25 10:46:34', '2015-03-25 09:46:34'),
(203, 246, 'Ayere', 'Jesumienpreder', '', 'STD0203', NULL, 'Male', '1970-01-01', 15, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 43, '2015-03-25 10:47:06', '2015-03-26 08:46:12'),
(204, 52, 'Ojuotimi', 'Ojo', '', 'STD0204', NULL, 'Male', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 54, '2015-03-25 10:51:21', '2015-03-25 09:51:21'),
(205, 212, 'Ifeoluwa', 'Oshunlola', '', 'STD0205', NULL, 'Female', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 54, '2015-03-25 10:53:42', '2015-03-25 09:53:42'),
(206, 243, 'Joel', 'Geoffrey', 'Promise', 'STD0206', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 10:54:55', '2015-03-25 09:54:55'),
(207, 244, 'Ebiye', 'Agadah', '', 'STD0207', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 11:15:22', '2015-03-25 10:15:22'),
(208, 104, 'Bolaji', 'Ishola', '', 'STD0208', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 11:19:42', '2015-03-25 10:19:42'),
(209, 216, 'Emeka', 'ONWUCHELU', '', 'STD0209', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 11:21:51', '2015-03-25 10:21:51'),
(210, 135, 'Ogheneyoma', 'HAMMAN -OBELS', '', 'STD0210', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 11:24:37', '2015-03-25 10:24:37'),
(211, 121, 'Faloye', 'AYOMIDE', '', 'STD0211', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 11:26:15', '2015-03-25 10:26:15'),
(212, 110, 'Emmanuel', 'TOBIAH', '', 'STD0212', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 11:27:45', '2015-03-25 10:27:45'),
(213, 103, 'Muhsin', 'MOMOH', '', 'STD0213', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 11:29:38', '2015-03-25 10:29:38'),
(214, 218, 'Paul', 'AKPAMA', '', 'STD0214', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 11:32:19', '2015-03-25 10:32:19'),
(215, 247, 'Emmanuel', 'DANIEL', '', 'STD0215', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 11:36:56', '2015-03-25 10:36:56'),
(216, 219, 'John', 'WIKIMOR', '', 'STD0216', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 11:39:02', '2015-03-25 10:39:02'),
(217, 220, 'Ebikabo-Owei', 'ZIWORITIN', '', 'STD0217', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 11:54:11', '2015-03-25 10:54:11'),
(218, 222, 'Abraham', 'MARKBERE', '', 'STD0218', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 11:55:43', '2015-03-25 10:55:44'),
(219, 230, 'Layefa', 'ELDINE', '', 'STD0219', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 11:57:35', '2015-03-25 10:57:35'),
(220, 234, 'Amos', 'SHADRACK', '', 'STD0220', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-25 11:59:34', '2015-03-25 10:59:34'),
(221, 162, 'Angel', 'Emmanuel', '', 'STD0221', NULL, 'Female', NULL, 9, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 23, '2015-03-25 12:15:57', '2015-03-25 11:15:57'),
(222, 163, 'Irene', 'Ikpi-Iyam', '', 'STD0222', NULL, 'Female', NULL, 9, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 23, '2015-03-25 12:20:24', '2015-03-25 11:20:24'),
(223, 240, 'Abdullahi', 'Raji', '', 'STD0223', NULL, 'Male', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 54, '2015-03-25 12:20:54', '2015-03-25 11:20:54'),
(224, 164, 'Precious', 'Johnsonj', '', 'STD0224', NULL, 'Female', NULL, 9, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 23, '2015-03-25 12:21:07', '2015-03-25 11:21:07'),
(225, 165, 'Viola', 'Okey-Ezealah', '', 'STD0225', NULL, 'Female', NULL, 9, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 23, '2015-03-25 12:22:52', '2015-03-25 11:22:52'),
(226, 166, 'Yemisi', 'Oshobu', '', 'STD0226', NULL, 'Female', NULL, 9, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 23, '2015-03-25 12:25:07', '2015-03-25 11:25:07'),
(227, 241, 'Samuel', 'Adeola', '', 'STD0227', NULL, 'Male', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 54, '2015-03-25 12:27:06', '2015-03-25 11:27:06'),
(228, 242, 'Obaloluwa', 'Oyedeji', '', 'STD0228', NULL, 'Male', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 54, '2015-03-25 12:28:02', '2015-03-25 11:28:02'),
(229, 127, 'Tokunbo', 'Sanni', '', 'STD0229', NULL, 'Female', '1970-01-01', 9, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 23, '2015-03-25 12:28:13', '2015-03-25 14:21:14'),
(230, 168, 'Anike', 'Sobowale', '', 'STD0230', NULL, 'Female', NULL, 9, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 23, '2015-03-25 12:28:49', '2015-03-25 11:28:49'),
(231, 169, 'Mariam', 'Yahaya', '', 'STD0231', NULL, 'Female', NULL, 9, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 23, '2015-03-25 12:30:07', '2015-03-25 11:30:07'),
(232, 253, 'AFENFIA', 'TAMARATAREBI', '', 'STD0232', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 46, '2015-03-25 01:34:03', '2015-03-25 12:34:03'),
(233, 253, 'OYINPREYE', 'BRIBENA', '', 'STD0233', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 46, '2015-03-25 01:35:02', '2015-03-25 12:35:02'),
(234, 253, 'TARILA ', 'DEINDUOMO', '', 'STD0234', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 46, '2015-03-25 01:36:15', '2015-03-25 12:36:15'),
(235, 253, 'MAJESTY', 'EKEDE', '', 'STD0235', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 46, '2015-03-25 01:36:56', '2015-03-25 12:36:56'),
(236, 253, 'PREMOBOWEI', 'FUMUDOH', '', 'STD0236', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 46, '2015-03-25 01:37:34', '2015-03-25 12:37:34'),
(237, 253, 'BINAEBI', 'GODWILL', '', 'STD0237', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 46, '2015-03-25 01:38:31', '2015-03-25 12:38:31'),
(238, 9, 'WILLIAM', 'HENRY-NKEKI ', '', 'STD0238', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 46, '2015-03-25 01:40:15', '2015-03-25 12:40:15'),
(239, 253, 'MELVIN', 'IPALIMOTE', '', 'STD0239', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 46, '2015-03-25 01:41:27', '2015-03-25 12:41:27'),
(240, 253, 'SAMSON ', 'JAMES ', '', 'STD0240', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 46, '2015-03-25 01:43:50', '2015-03-25 12:43:50'),
(241, 253, 'ELIZER', 'KPEMI', '', 'STD0241', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 46, '2015-03-25 01:44:28', '2015-03-25 12:44:28'),
(242, 253, 'OYINTARILA', 'NDIOMU', '', 'STD0242', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 46, '2015-03-25 01:45:47', '2015-03-25 12:45:47'),
(243, 254, 'FAVOUR', 'NWOKEKE', '', 'STD0243', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 46, '2015-03-25 01:46:26', '2015-03-25 12:46:26'),
(244, 253, 'FRANCIS', 'OKOROTIE ', '', 'STD0244', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 46, '2015-03-25 01:47:34', '2015-03-25 12:47:34'),
(245, 262, ' OLADEPO', 'OLANIYONU', '', 'STD0245', NULL, 'Male', '1970-01-01', 11, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 46, '2015-03-25 01:48:23', '2015-03-25 14:16:36'),
(246, 253, 'REIGNALD', 'ONUMAJURU', '', 'STD0246', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 46, '2015-03-25 01:49:03', '2015-03-25 12:49:04'),
(247, 253, 'DIVINE-FAVOUR ', 'UGIRI', '', 'STD0247', NULL, 'Male', NULL, 11, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 46, '2015-03-25 01:52:07', '2015-03-25 12:52:07'),
(248, 2, 'DAVID ', 'ADENIRAN', '', 'STD0248', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 02:42:47', '2015-03-25 13:42:47'),
(249, 248, 'Chijioke', 'AKUNWA', '', 'STD0249', NULL, 'Male', '1970-01-01', 22, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 42, '2015-03-25 02:45:27', '2015-03-25 21:27:33'),
(250, 249, 'Obioma', 'ANOKWURU', '', 'STD0250', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 02:46:07', '2015-03-25 13:46:07'),
(251, 225, 'Adekunle', 'AWOLAJA ', '', 'STD0251', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 02:47:34', '2015-03-25 13:47:34'),
(252, 2, ' SARAH ', 'ADENIRAN', 'ADEOLA', 'STD0252', NULL, 'Male', NULL, 14, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-03-25 02:47:43', '2015-03-25 13:47:43'),
(253, 251, 'Garba', 'BELLO', '', 'STD0253', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 02:53:54', '2015-03-25 13:53:54'),
(254, 252, 'DAVID ', 'DADINSON-OGBOGBO ', '', 'STD0254', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 02:56:25', '2015-03-25 13:56:25'),
(255, 257, 'Owabomate', 'DAPPAH', '', 'STD0255', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 02:57:40', '2015-03-25 13:57:40'),
(256, 8, 'Isaac', 'EGBEDEYI ', '', 'STD0256', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 03:00:11', '2015-03-25 14:00:11'),
(257, 258, 'EBUBECHI', 'EZIMOHA ', '', 'STD0257', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 03:00:48', '2015-03-25 14:00:48'),
(258, 84, 'Paul', 'ISIBOR', '', 'STD0258', NULL, 'Male', '1970-01-01', 22, NULL, NULL, 1, '', 1, NULL, 0, 140, 1, 42, '2015-03-25 03:02:14', '2015-03-25 14:22:19'),
(259, 84, 'Peter', 'ISIBOR', '', 'STD0259', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 03:03:30', '2015-03-25 14:03:30'),
(260, 105, 'Shawn', 'MBAEGBU ', '', 'STD0260', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 03:05:44', '2015-03-25 14:05:44'),
(261, 259, 'MIRACLE', 'NNOROM,', '', 'STD0261', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 03:06:52', '2015-03-25 14:06:52'),
(262, 260, 'OGBECHIE', 'CHIDIEBUBE', '', 'STD0262', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 03:08:33', '2015-03-25 14:08:33'),
(263, 261, 'EBUBE ', 'OKEREAFOR ', '', 'STD0263', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 03:10:51', '2015-03-25 14:10:51'),
(264, 262, 'OLADIPO', 'OLANIYONU', '', 'STD0264', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 03:12:33', '2015-03-25 14:12:33'),
(265, 72, 'Ajiboye', 'OLAOYE ', '', 'STD0265', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 03:14:53', '2015-03-25 14:14:53'),
(266, 229, 'Chisom ', 'OWHONDA', '', 'STD0266', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 03:16:29', '2015-03-25 14:16:29'),
(267, 154, 'SOMTOCHUKWU', 'UDUJI-EMENIKE ', '', 'STD0267', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 03:17:47', '2015-03-25 14:17:47'),
(268, 263, 'RINCHA', 'UNAH ', '', 'STD0268', NULL, 'Male', NULL, 22, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 42, '2015-03-25 03:18:26', '2015-03-25 14:18:26'),
(269, 11, ' KOLADE', 'NICK-IBITOYE', '', 'STD0269', NULL, 'Male', NULL, 17, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 32, '2015-03-25 03:27:28', '2015-03-25 14:27:28'),
(270, 224, 'KEHINDE', 'OSINBAJO', 'BOLUTITO', 'STD0270', NULL, 'Male', NULL, 17, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 32, '2015-03-25 03:32:04', '2015-03-25 14:32:04'),
(271, 168, 'AYOMIDE', 'SOBOWALE', 'GABRIEL', 'STD0271', NULL, 'Male', NULL, 17, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 32, '2015-03-25 03:34:44', '2015-03-25 14:34:44'),
(272, 146, 'OLUWANIFEMI', 'BAKRE', 'SAHEED', 'STD0272', NULL, 'Male', NULL, 17, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 32, '2015-03-25 04:41:05', '2015-03-25 15:41:05'),
(273, 267, 'DAVID', 'ASAKITIPI', 'EJIROGHENE', 'STD0273', NULL, 'Male', NULL, 17, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 32, '2015-03-25 04:42:15', '2015-03-25 15:42:15'),
(274, 266, 'OBOGHENE', 'AGBAWHE', '', 'STD0274', NULL, 'Male', NULL, 17, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 32, '2015-03-25 04:51:30', '2015-03-25 15:51:30'),
(275, 265, 'ONYEKACHUKWU', 'OBIDIEGWU', '', 'STD0275', NULL, 'Male', NULL, 17, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 32, '2015-03-25 04:58:23', '2015-03-25 15:58:23'),
(276, 264, 'NONSO', 'IGWE', '', 'STD0276', NULL, 'Male', NULL, 17, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 32, '2015-03-25 04:59:44', '2015-03-25 15:59:44'),
(277, 173, 'OLAMIDE', 'ALAYANDE', '', 'STD0277', NULL, 'Female', NULL, 30, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 59, '2015-03-25 05:01:45', '2015-03-25 16:01:45'),
(278, 193, 'ENIOLA ', 'FaYOMI', '', 'STD0278', NULL, 'Female', NULL, 30, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 59, '2015-03-25 05:04:17', '2015-03-25 16:04:17'),
(279, 268, 'KOREDE', 'ODESANYA', '', 'STD0279', NULL, 'Female', NULL, 30, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 59, '2015-03-25 05:05:06', '2015-03-25 16:05:06'),
(280, 269, 'TEMILOLUWA', 'OSHINAIKE', '', 'STD0280', NULL, 'Female', NULL, 30, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 59, '2015-03-25 05:06:30', '2015-03-25 16:06:30'),
(281, 270, 'YEWANDE', 'TOOGUN', '', 'STD0281', NULL, 'Female', NULL, 30, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 59, '2015-03-25 05:07:28', '2015-03-25 16:07:28'),
(282, 271, 'JEREMIAH', 'ENI', '', 'STD0282', NULL, 'Male', NULL, 30, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 59, '2015-03-25 05:08:14', '2015-03-25 16:08:14'),
(283, 272, 'DAMILARE', 'OPARA', 'ONYEKACHI', 'STD0283', NULL, 'Male', NULL, 17, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 32, '2015-03-25 05:08:59', '2015-03-25 16:08:59'),
(284, 63, 'ADESEYE', 'OKESINA', '', 'STD0284', NULL, 'Male', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-03-26 10:53:48', '2015-03-26 09:53:48'),
(285, 273, 'Daaiyefumasu', 'NICHOLAS', '', 'STD0285', NULL, 'Male', NULL, 12, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 43, '2015-03-26 12:24:41', '2015-03-26 11:24:41');

-- --------------------------------------------------------

--
-- Table structure for table `students_classes`
--

CREATE TABLE IF NOT EXISTS `students_classes` (
`student_class_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `academic_year_id` int(11) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=288 ;

--
-- Dumping data for table `students_classes`
--

INSERT INTO `students_classes` (`student_class_id`, `student_id`, `class_id`, `academic_year_id`) VALUES
(1, 1, 2, 1),
(2, 2, 2, 1),
(4, 3, 2, 1),
(5, 4, 2, 1),
(6, 5, 2, 1),
(7, 6, 2, 1),
(9, 7, 2, 1),
(12, 10, 2, 1),
(13, 11, 2, 1),
(14, 12, 2, 1),
(15, 13, 2, 1),
(16, 14, 2, 1),
(17, 15, 2, 1),
(18, 16, 2, 1),
(19, 17, 2, 1),
(20, 18, 2, 1),
(21, 19, 7, 1),
(22, 20, 30, 1),
(131, 21, 25, 1),
(23, 22, 14, 1),
(126, 24, 15, 1),
(25, 25, 15, 1),
(26, 26, 14, 1),
(27, 27, 15, 1),
(28, 28, 14, 1),
(29, 29, 15, 1),
(30, 30, 15, 1),
(31, 31, 14, 1),
(32, 32, 14, 1),
(33, 33, 15, 1),
(34, 34, 15, 1),
(35, 35, 15, 1),
(36, 36, 14, 1),
(37, 37, 14, 1),
(38, 38, 14, 1),
(39, 39, 14, 1),
(40, 40, 14, 1),
(41, 41, 14, 1),
(42, 42, 14, 1),
(43, 43, 14, 1),
(44, 44, 14, 1),
(45, 45, 14, 1),
(46, 46, 14, 1),
(47, 47, 14, 1),
(48, 48, 10, 1),
(49, 49, 10, 1),
(50, 50, 10, 1),
(51, 51, 10, 1),
(52, 52, 10, 1),
(53, 53, 10, 1),
(54, 54, 10, 1),
(55, 55, 10, 1),
(56, 56, 10, 1),
(57, 57, 4, 1),
(58, 58, 4, 1),
(59, 59, 4, 1),
(60, 60, 4, 1),
(61, 61, 4, 1),
(62, 62, 4, 1),
(63, 63, 4, 1),
(64, 64, 4, 1),
(65, 65, 4, 1),
(66, 66, 13, 1),
(67, 67, 13, 1),
(68, 68, 13, 1),
(69, 69, 13, 1),
(70, 70, 13, 1),
(71, 71, 13, 1),
(72, 72, 13, 1),
(73, 73, 13, 1),
(74, 74, 13, 1),
(75, 75, 13, 1),
(76, 76, 13, 1),
(77, 77, 13, 1),
(78, 78, 13, 1),
(79, 79, 13, 1),
(80, 80, 13, 1),
(81, 81, 13, 1),
(82, 82, 13, 1),
(83, 83, 13, 1),
(84, 84, 13, 1),
(85, 85, 29, 1),
(86, 86, 29, 1),
(87, 87, 29, 1),
(88, 88, 29, 1),
(89, 89, 29, 1),
(90, 90, 29, 1),
(91, 91, 29, 1),
(92, 92, 29, 1),
(93, 93, 24, 1),
(94, 94, 29, 1),
(95, 95, 29, 1),
(96, 96, 24, 1),
(97, 97, 29, 1),
(98, 98, 24, 1),
(99, 99, 29, 1),
(100, 100, 24, 1),
(101, 101, 29, 1),
(102, 102, 24, 1),
(103, 103, 29, 1),
(104, 104, 24, 1),
(105, 105, 29, 1),
(106, 106, 24, 1),
(107, 107, 29, 1),
(108, 108, 29, 1),
(109, 109, 24, 1),
(110, 110, 24, 1),
(111, 111, 24, 1),
(112, 112, 24, 1),
(113, 113, 24, 1),
(114, 114, 24, 1),
(115, 115, 24, 1),
(116, 116, 24, 1),
(117, 117, 24, 1),
(118, 118, 1, 1),
(119, 119, 24, 1),
(120, 120, 7, 1),
(121, 121, 7, 1),
(122, 122, 7, 1),
(123, 123, 7, 1),
(124, 124, 7, 1),
(125, 125, 7, 1),
(127, 126, 7, 1),
(128, 127, 7, 1),
(129, 128, 7, 1),
(130, 129, 1, 1),
(132, 130, 7, 1),
(133, 131, 1, 1),
(134, 132, 7, 1),
(135, 133, 7, 1),
(136, 134, 24, 1),
(137, 135, 7, 1),
(138, 136, 24, 1),
(139, 137, 1, 1),
(140, 138, 1, 1),
(141, 139, 24, 1),
(142, 140, 1, 1),
(143, 141, 9, 1),
(144, 142, 1, 1),
(145, 143, 1, 1),
(146, 144, 1, 1),
(147, 145, 1, 1),
(148, 146, 20, 1),
(149, 147, 20, 1),
(150, 148, 27, 1),
(151, 149, 27, 1),
(152, 150, 20, 1),
(153, 151, 27, 1),
(154, 152, 27, 1),
(155, 153, 27, 1),
(156, 154, 20, 1),
(157, 155, 27, 1),
(158, 156, 27, 1),
(159, 157, 27, 1),
(160, 158, 20, 1),
(161, 159, 20, 1),
(162, 160, 27, 1),
(163, 161, 27, 1),
(164, 162, 27, 1),
(165, 163, 27, 1),
(166, 164, 27, 1),
(167, 165, 27, 1),
(168, 166, 27, 1),
(169, 167, 20, 1),
(170, 168, 20, 1),
(171, 169, 20, 1),
(172, 170, 20, 1),
(174, 172, 20, 1),
(175, 173, 20, 1),
(176, 174, 20, 1),
(178, 176, 20, 1),
(179, 177, 20, 1),
(180, 178, 20, 1),
(181, 179, 20, 1),
(182, 180, 25, 1),
(183, 181, 25, 1),
(184, 182, 25, 1),
(185, 183, 25, 1),
(186, 184, 25, 1),
(187, 185, 25, 1),
(188, 186, 25, 1),
(189, 187, 25, 1),
(190, 188, 25, 1),
(191, 189, 19, 1),
(192, 190, 19, 1),
(193, 191, 19, 1),
(194, 192, 19, 1),
(195, 193, 19, 1),
(196, 194, 19, 1),
(197, 195, 19, 1),
(198, 196, 19, 1),
(199, 197, 5, 1),
(200, 198, 5, 1),
(201, 199, 5, 1),
(202, 200, 5, 1),
(203, 201, 5, 1),
(204, 202, 5, 1),
(205, 203, 15, 1),
(206, 204, 5, 1),
(207, 205, 5, 1),
(208, 206, 12, 1),
(209, 207, 12, 1),
(210, 208, 12, 1),
(211, 209, 12, 1),
(212, 210, 12, 1),
(213, 211, 12, 1),
(214, 212, 12, 1),
(215, 213, 12, 1),
(216, 214, 12, 1),
(217, 215, 12, 1),
(218, 216, 12, 1),
(219, 217, 12, 1),
(220, 218, 12, 1),
(221, 219, 12, 1),
(222, 220, 12, 1),
(223, 221, 9, 1),
(224, 222, 9, 1),
(225, 223, 5, 1),
(226, 224, 9, 1),
(227, 225, 9, 1),
(228, 226, 9, 1),
(229, 227, 5, 1),
(230, 228, 5, 1),
(231, 229, 9, 1),
(232, 230, 9, 1),
(233, 231, 9, 1),
(234, 232, 11, 1),
(235, 233, 11, 1),
(236, 234, 11, 1),
(237, 235, 11, 1),
(238, 236, 11, 1),
(239, 237, 11, 1),
(240, 238, 11, 1),
(241, 239, 11, 1),
(242, 240, 11, 1),
(243, 241, 11, 1),
(244, 242, 11, 1),
(245, 243, 11, 1),
(246, 244, 11, 1),
(247, 245, 11, 1),
(248, 246, 11, 1),
(249, 247, 11, 1),
(250, 248, 22, 1),
(251, 249, 22, 1),
(252, 250, 22, 1),
(253, 251, 22, 1),
(254, 252, 14, 1),
(255, 253, 22, 1),
(256, 254, 22, 1),
(257, 255, 22, 1),
(258, 256, 22, 1),
(259, 257, 22, 1),
(270, 258, 22, 1),
(260, 259, 22, 1),
(261, 260, 22, 1),
(262, 261, 22, 1),
(263, 262, 22, 1),
(264, 263, 22, 1),
(265, 264, 22, 1),
(266, 265, 22, 1),
(267, 266, 22, 1),
(268, 267, 22, 1),
(269, 268, 22, 1),
(271, 269, 17, 1),
(272, 270, 17, 1),
(273, 271, 17, 1),
(274, 272, 17, 1),
(275, 273, 17, 1),
(276, 274, 17, 1),
(277, 275, 17, 1),
(278, 276, 17, 1),
(279, 277, 30, 1),
(280, 278, 30, 1),
(281, 279, 30, 1),
(282, 280, 30, 1),
(283, 281, 30, 1),
(284, 282, 30, 1),
(285, 283, 17, 1),
(286, 284, 1, 1),
(287, 285, 12, 1);

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
,`class_id` int(11)
,`subject_classlevel_id` int(11)
,`student_name` varchar(153)
,`student_no` varchar(50)
,`class_name` varchar(50)
,`subject_id` int(11)
,`subject_name` varchar(50)
,`classlevel_id` int(11)
,`classlevel` varchar(50)
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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=198 ;

--
-- Dumping data for table `subject_classlevels`
--

INSERT INTO `subject_classlevels` (`subject_classlevel_id`, `subject_id`, `classlevel_id`, `class_id`, `academic_term_id`, `examstatus_id`) VALUES
(150, 1, 1, NULL, 1, 1),
(10, 1, 2, NULL, 1, 1),
(3, 1, 3, NULL, 1, 1),
(4, 1, 4, NULL, 1, 1),
(5, 1, 5, NULL, 1, 1),
(6, 1, 6, NULL, 1, 1),
(137, 2, 1, NULL, 1, 1),
(9, 2, 2, NULL, 1, 1),
(11, 2, 3, NULL, 1, 1),
(138, 2, 4, NULL, 1, 1),
(140, 2, 5, NULL, 1, 1),
(142, 2, 6, NULL, 1, 1),
(7, 3, 1, NULL, 1, 1),
(8, 3, 2, NULL, 1, 1),
(12, 3, 3, NULL, 1, 1),
(14, 4, 2, NULL, 1, 1),
(147, 4, 3, NULL, 1, 1),
(15, 5, 1, NULL, 1, 1),
(16, 5, 2, NULL, 1, 1),
(17, 5, 3, NULL, 1, 1),
(18, 6, 1, NULL, 1, 1),
(20, 6, 2, NULL, 1, 1),
(19, 6, 3, NULL, 1, 1),
(186, 7, 1, NULL, 1, 1),
(22, 7, 2, NULL, 1, 1),
(23, 7, 3, NULL, 1, 1),
(24, 7, 4, NULL, 1, 1),
(25, 7, 5, NULL, 1, 1),
(26, 7, 6, NULL, 1, 1),
(196, 8, 1, NULL, 1, 1),
(197, 8, 2, NULL, 1, 1),
(28, 8, 3, NULL, 1, 1),
(188, 8, 4, NULL, 1, 1),
(189, 8, 5, NULL, 1, 1),
(190, 8, 6, NULL, 1, 1),
(29, 9, 1, NULL, 1, 1),
(32, 9, 2, NULL, 1, 1),
(33, 9, 3, NULL, 1, 1),
(43, 9, 4, NULL, 1, 1),
(45, 9, 5, NULL, 1, 1),
(47, 9, 6, NULL, 1, 1),
(58, 10, 4, NULL, 1, 1),
(59, 10, 5, NULL, 1, 1),
(61, 10, 6, NULL, 1, 1),
(76, 11, 1, NULL, 1, 1),
(102, 11, 2, NULL, 1, 1),
(78, 11, 3, NULL, 1, 1),
(86, 11, 4, NULL, 1, 1),
(88, 11, 5, NULL, 1, 1),
(91, 11, 6, NULL, 1, 1),
(108, 12, 1, NULL, 1, 1),
(109, 12, 2, NULL, 1, 1),
(187, 12, 3, NULL, 1, 1),
(111, 12, 4, NULL, 1, 1),
(118, 12, 5, NULL, 1, 1),
(122, 12, 6, NULL, 1, 1),
(126, 13, 1, NULL, 1, 1),
(139, 13, 2, NULL, 1, 1),
(128, 13, 3, NULL, 1, 1),
(129, 13, 4, NULL, 1, 1),
(141, 13, 5, NULL, 1, 1),
(144, 13, 6, NULL, 1, 1),
(130, 14, 1, NULL, 1, 1),
(131, 14, 2, NULL, 1, 1),
(133, 14, 3, NULL, 1, 1),
(134, 14, 4, NULL, 1, 1),
(135, 14, 5, NULL, 1, 1),
(136, 14, 6, NULL, 1, 1),
(143, 15, 1, NULL, 1, 1),
(145, 15, 2, NULL, 1, 1),
(146, 15, 3, NULL, 1, 1),
(112, 16, 1, NULL, 1, 1),
(113, 16, 2, NULL, 1, 1),
(114, 16, 3, NULL, 1, 1),
(115, 16, 4, NULL, 1, 1),
(116, 16, 5, NULL, 1, 1),
(117, 16, 6, NULL, 1, 1),
(119, 17, 1, NULL, 1, 1),
(120, 17, 2, NULL, 1, 1),
(121, 17, 3, NULL, 1, 1),
(123, 17, 4, NULL, 1, 1),
(124, 17, 5, NULL, 1, 1),
(127, 17, 6, NULL, 1, 1),
(30, 18, 4, NULL, 1, 1),
(31, 18, 5, NULL, 1, 1),
(34, 18, 6, NULL, 1, 1),
(35, 19, 4, NULL, 1, 1),
(36, 19, 5, NULL, 1, 1),
(37, 19, 6, NULL, 1, 1),
(38, 20, 4, NULL, 1, 1),
(40, 20, 5, NULL, 1, 1),
(41, 20, 6, NULL, 1, 1),
(42, 21, 4, NULL, 1, 1),
(44, 21, 5, NULL, 1, 1),
(46, 21, 6, NULL, 1, 1),
(48, 22, 4, NULL, 1, 1),
(49, 22, 5, NULL, 1, 1),
(51, 22, 6, NULL, 1, 1),
(53, 23, 4, NULL, 1, 1),
(177, 23, 5, NULL, 1, 1),
(54, 23, 6, NULL, 1, 1),
(56, 24, 4, NULL, 1, 1),
(57, 24, 5, NULL, 1, 1),
(60, 24, 6, NULL, 1, 1),
(62, 25, 4, NULL, 1, 1),
(63, 25, 5, NULL, 1, 1),
(65, 25, 6, NULL, 1, 1),
(64, 26, 1, NULL, 1, 1),
(149, 26, 2, NULL, 1, 1),
(66, 26, 3, NULL, 1, 1),
(69, 26, 4, NULL, 1, 1),
(71, 26, 5, NULL, 1, 1),
(72, 26, 6, NULL, 1, 1),
(68, 27, 5, NULL, 1, 1),
(70, 27, 6, NULL, 1, 1),
(73, 28, 4, NULL, 1, 1),
(74, 28, 5, NULL, 1, 1),
(75, 28, 6, NULL, 1, 1),
(67, 29, 4, NULL, 1, 1),
(77, 29, 5, NULL, 1, 1),
(79, 29, 6, NULL, 1, 1),
(81, 30, 4, NULL, 1, 1),
(82, 30, 5, NULL, 1, 1),
(87, 30, 6, NULL, 1, 1),
(93, 31, 4, NULL, 1, 1),
(94, 31, 5, NULL, 1, 1),
(95, 31, 6, NULL, 1, 1),
(97, 32, 4, NULL, 1, 1),
(98, 32, 5, NULL, 1, 1),
(99, 32, 6, NULL, 1, 1),
(100, 33, 4, NULL, 1, 1),
(101, 33, 5, NULL, 1, 1),
(103, 33, 6, NULL, 1, 1),
(105, 34, 4, NULL, 1, 1),
(106, 34, 5, NULL, 1, 1),
(107, 34, 6, NULL, 1, 1),
(154, 35, 4, NULL, 1, 1),
(155, 35, 5, NULL, 1, 1),
(156, 35, 6, NULL, 1, 1),
(163, 36, 4, NULL, 1, 1),
(165, 36, 5, NULL, 1, 1),
(164, 36, 6, NULL, 1, 1),
(157, 37, 1, NULL, 1, 1),
(158, 37, 2, NULL, 1, 1),
(159, 37, 3, NULL, 1, 1),
(160, 37, 4, NULL, 1, 1),
(161, 37, 5, NULL, 1, 1),
(162, 37, 6, NULL, 1, 1),
(166, 38, 1, NULL, 1, 1),
(167, 38, 2, NULL, 1, 1),
(168, 38, 3, NULL, 1, 1),
(169, 38, 4, NULL, 1, 1),
(170, 38, 5, NULL, 1, 1),
(171, 38, 6, NULL, 1, 1),
(183, 39, 1, NULL, 1, 1),
(184, 39, 2, NULL, 1, 1),
(185, 39, 3, NULL, 1, 1),
(172, 40, 4, -1, 1, 1),
(179, 40, 5, NULL, 1, 1),
(178, 40, 6, NULL, 1, 1),
(180, 41, 4, NULL, 1, 1),
(181, 41, 5, NULL, 1, 1),
(182, 41, 6, NULL, 1, 1),
(191, 42, 1, NULL, 1, 1),
(192, 42, 2, NULL, 1, 1),
(193, 42, 3, NULL, 1, 1),
(194, 42, 4, NULL, 1, 1),
(195, 42, 5, NULL, 1, 1),
(174, 43, 1, NULL, 1, 1),
(175, 43, 2, NULL, 1, 1),
(176, 43, 3, NULL, 1, 1);

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
,`exam_status` varchar(13)
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
(1, 'Mathematics & Computer'),
(2, 'Languages'),
(3, 'Sciences'),
(5, 'Humanities'),
(6, 'Business Studies'),
(7, 'Vocational Studies');

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
(1, 2, 15),
(1, 2, 143),
(1, 2, 196),
(2, 2, 15),
(2, 2, 143),
(2, 2, 196),
(3, 2, 15),
(3, 2, 196),
(4, 2, 15),
(4, 2, 143),
(4, 2, 196),
(5, 2, 15),
(5, 2, 196),
(6, 2, 15),
(6, 2, 143),
(6, 2, 196),
(7, 2, 15),
(7, 2, 196),
(10, 2, 15),
(10, 2, 143),
(10, 2, 196),
(11, 2, 15),
(11, 2, 196),
(12, 2, 15),
(12, 2, 143),
(12, 2, 196),
(13, 2, 15),
(13, 2, 196),
(14, 2, 15),
(14, 2, 143),
(14, 2, 196),
(15, 2, 15),
(15, 2, 196),
(16, 2, 15),
(16, 2, 143),
(16, 2, 196),
(17, 2, 15),
(17, 2, 196),
(18, 2, 15),
(18, 2, 143),
(18, 2, 196),
(19, 7, 197),
(20, 30, 117),
(20, 30, 178),
(21, 25, 98),
(22, 14, 17),
(22, 14, 114),
(22, 14, 146),
(24, 15, 17),
(24, 15, 114),
(25, 15, 17),
(26, 14, 17),
(26, 14, 114),
(27, 15, 17),
(27, 15, 114),
(28, 14, 17),
(28, 14, 114),
(28, 14, 146),
(29, 15, 17),
(29, 15, 114),
(30, 15, 17),
(30, 15, 114),
(30, 15, 146),
(31, 14, 17),
(31, 14, 114),
(31, 14, 146),
(32, 14, 17),
(32, 14, 114),
(33, 15, 17),
(33, 15, 114),
(33, 15, 146),
(34, 15, 17),
(34, 15, 114),
(34, 15, 146),
(35, 15, 17),
(35, 15, 114),
(36, 14, 17),
(36, 14, 114),
(37, 14, 17),
(37, 14, 114),
(38, 14, 17),
(38, 14, 114),
(38, 14, 146),
(39, 14, 17),
(39, 14, 114),
(40, 14, 17),
(40, 14, 114),
(41, 14, 17),
(41, 14, 114),
(42, 14, 17),
(43, 14, 17),
(43, 14, 114),
(43, 14, 146),
(44, 14, 17),
(44, 14, 114),
(45, 14, 17),
(45, 14, 114),
(46, 14, 17),
(46, 14, 114),
(47, 14, 17),
(47, 14, 114),
(48, 10, 16),
(48, 10, 145),
(48, 10, 197),
(49, 10, 16),
(49, 10, 197),
(50, 10, 16),
(50, 10, 145),
(50, 10, 197),
(51, 10, 16),
(51, 10, 145),
(51, 10, 197),
(52, 10, 16),
(52, 10, 145),
(52, 10, 197),
(53, 10, 16),
(53, 10, 197),
(54, 10, 16),
(54, 10, 197),
(55, 10, 16),
(55, 10, 145),
(55, 10, 197),
(56, 10, 16),
(56, 10, 145),
(56, 10, 197),
(57, 4, 15),
(57, 4, 112),
(57, 4, 196),
(58, 4, 15),
(58, 4, 112),
(58, 4, 196),
(59, 4, 15),
(59, 4, 196),
(60, 4, 15),
(60, 4, 112),
(60, 4, 196),
(61, 4, 15),
(61, 4, 112),
(61, 4, 196),
(62, 4, 15),
(62, 4, 112),
(62, 4, 196),
(63, 4, 15),
(63, 4, 112),
(63, 4, 196),
(64, 4, 15),
(64, 4, 112),
(64, 4, 196),
(65, 4, 15),
(65, 4, 112),
(65, 4, 196),
(66, 13, 17),
(66, 13, 146),
(67, 13, 17),
(67, 13, 146),
(68, 13, 17),
(68, 13, 114),
(69, 13, 17),
(69, 13, 114),
(70, 13, 17),
(70, 13, 114),
(71, 13, 17),
(71, 13, 114),
(72, 13, 17),
(72, 13, 114),
(72, 13, 146),
(73, 13, 17),
(73, 13, 114),
(74, 13, 17),
(74, 13, 114),
(75, 13, 17),
(75, 13, 114),
(76, 13, 17),
(76, 13, 114),
(76, 13, 146),
(77, 13, 17),
(78, 13, 17),
(78, 13, 114),
(79, 13, 17),
(79, 13, 114),
(80, 13, 17),
(80, 13, 114),
(80, 13, 146),
(81, 13, 17),
(81, 13, 146),
(82, 13, 17),
(82, 13, 146),
(83, 13, 17),
(83, 13, 114),
(84, 13, 17),
(84, 13, 114),
(89, 29, 117),
(91, 29, 117),
(92, 29, 117),
(93, 24, 98),
(95, 29, 178),
(96, 24, 98),
(98, 24, 98),
(98, 24, 116),
(99, 29, 117),
(100, 24, 98),
(102, 24, 57),
(102, 24, 98),
(102, 24, 179),
(103, 29, 60),
(103, 29, 117),
(104, 24, 98),
(106, 24, 98),
(108, 29, 117),
(109, 24, 98),
(110, 24, 57),
(110, 24, 98),
(110, 24, 179),
(111, 24, 98),
(111, 24, 116),
(111, 24, 179),
(112, 24, 98),
(112, 24, 116),
(113, 24, 98),
(113, 24, 179),
(114, 24, 98),
(115, 24, 98),
(116, 24, 98),
(116, 24, 179),
(117, 24, 98),
(118, 1, 15),
(118, 1, 196),
(119, 24, 98),
(120, 7, 145),
(120, 7, 197),
(121, 7, 145),
(121, 7, 197),
(122, 7, 145),
(122, 7, 197),
(123, 7, 145),
(123, 7, 197),
(124, 7, 197),
(125, 7, 197),
(126, 7, 197),
(127, 7, 197),
(128, 7, 197),
(129, 1, 15),
(129, 1, 196),
(130, 7, 197),
(131, 1, 15),
(131, 1, 196),
(132, 7, 145),
(132, 7, 197),
(133, 7, 145),
(133, 7, 197),
(134, 24, 98),
(135, 7, 145),
(135, 7, 197),
(136, 24, 98),
(136, 24, 116),
(137, 1, 15),
(137, 1, 112),
(137, 1, 196),
(138, 1, 15),
(138, 1, 112),
(138, 1, 196),
(139, 24, 98),
(140, 1, 15),
(140, 1, 112),
(140, 1, 196),
(141, 9, 113),
(141, 9, 145),
(141, 9, 197),
(142, 1, 15),
(142, 1, 112),
(142, 1, 143),
(142, 1, 196),
(143, 1, 15),
(143, 1, 112),
(143, 1, 196),
(144, 1, 15),
(144, 1, 112),
(144, 1, 143),
(144, 1, 196),
(145, 1, 15),
(145, 1, 112),
(145, 1, 196),
(167, 20, 172),
(168, 20, 172),
(169, 20, 56),
(169, 20, 172),
(172, 20, 172),
(173, 20, 172),
(174, 20, 172),
(176, 20, 172),
(177, 20, 56),
(178, 20, 56),
(179, 20, 56),
(179, 20, 172),
(180, 25, 98),
(181, 25, 98),
(182, 25, 98),
(183, 25, 98),
(184, 25, 98),
(185, 25, 98),
(186, 25, 98),
(187, 25, 98),
(188, 25, 98),
(192, 19, 115),
(196, 19, 115),
(197, 5, 15),
(197, 5, 112),
(197, 5, 196),
(198, 5, 15),
(198, 5, 112),
(198, 5, 143),
(198, 5, 196),
(199, 5, 15),
(199, 5, 112),
(199, 5, 143),
(199, 5, 196),
(200, 5, 15),
(200, 5, 143),
(200, 5, 196),
(201, 5, 15),
(201, 5, 143),
(201, 5, 196),
(202, 5, 15),
(202, 5, 112),
(202, 5, 143),
(202, 5, 196),
(203, 15, 17),
(204, 5, 15),
(204, 5, 112),
(204, 5, 143),
(204, 5, 196),
(205, 5, 15),
(205, 5, 143),
(205, 5, 196),
(206, 12, 17),
(207, 12, 17),
(208, 12, 17),
(209, 12, 17),
(210, 12, 17),
(210, 12, 146),
(211, 12, 17),
(212, 12, 17),
(213, 12, 17),
(213, 12, 146),
(214, 12, 17),
(215, 12, 17),
(216, 12, 17),
(217, 12, 17),
(218, 12, 17),
(219, 12, 17),
(220, 12, 17),
(221, 9, 113),
(221, 9, 145),
(221, 9, 197),
(222, 9, 113),
(222, 9, 145),
(222, 9, 197),
(223, 5, 15),
(223, 5, 143),
(223, 5, 196),
(224, 9, 113),
(224, 9, 145),
(224, 9, 197),
(225, 9, 113),
(225, 9, 145),
(225, 9, 197),
(226, 9, 113),
(226, 9, 145),
(226, 9, 197),
(227, 5, 15),
(227, 5, 112),
(227, 5, 196),
(228, 5, 15),
(228, 5, 112),
(228, 5, 143),
(228, 5, 196),
(229, 9, 113),
(229, 9, 145),
(229, 9, 197),
(230, 9, 113),
(230, 9, 197),
(231, 9, 197),
(232, 11, 17),
(232, 11, 146),
(233, 11, 17),
(233, 11, 146),
(234, 11, 17),
(234, 11, 146),
(235, 11, 17),
(236, 11, 17),
(236, 11, 146),
(237, 11, 17),
(238, 11, 17),
(238, 11, 146),
(239, 11, 17),
(240, 11, 17),
(241, 11, 17),
(242, 11, 17),
(242, 11, 146),
(243, 11, 17),
(243, 11, 146),
(244, 11, 17),
(244, 11, 146),
(245, 11, 17),
(246, 11, 17),
(246, 11, 146),
(247, 11, 17),
(247, 11, 146),
(248, 22, 98),
(249, 22, 98),
(250, 22, 98),
(251, 22, 98),
(252, 14, 17),
(252, 14, 114),
(253, 22, 98),
(254, 22, 98),
(255, 22, 98),
(256, 22, 98),
(257, 22, 98),
(258, 22, 98),
(259, 22, 57),
(259, 22, 98),
(259, 22, 179),
(260, 22, 98),
(261, 22, 98),
(262, 22, 98),
(263, 22, 98),
(264, 22, 98),
(265, 22, 98),
(266, 22, 98),
(267, 22, 98),
(268, 22, 98),
(269, 17, 172),
(271, 17, 172),
(272, 17, 172),
(273, 17, 172),
(274, 17, 172),
(275, 17, 172),
(276, 17, 172),
(277, 30, 60),
(279, 30, 178),
(284, 1, 112),
(284, 1, 196);

-- --------------------------------------------------------

--
-- Table structure for table `subjects`
--

CREATE TABLE IF NOT EXISTS `subjects` (
`subject_id` int(3) NOT NULL,
  `subject_name` varchar(50) DEFAULT NULL,
  `subject_group_id` int(11) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=44 ;

--
-- Dumping data for table `subjects`
--

INSERT INTO `subjects` (`subject_id`, `subject_name`, `subject_group_id`) VALUES
(1, 'English Language', 2),
(2, 'Mathematics', 1),
(3, 'Basic Science', 3),
(5, 'Business Studies', 6),
(6, 'Social Studies', 5),
(7, 'French', 2),
(8, 'P.H Education', 3),
(9, 'Computer ', 1),
(10, 'Visual Arts', 7),
(11, 'Hausa', 2),
(12, 'Igbo', 2),
(13, 'Yoruba', 2),
(14, 'Agric Science', 3),
(15, 'Home Economics', 7),
(16, 'C.R.S', 5),
(17, 'I.R.S', 5),
(18, 'Geography', 5),
(19, 'Lit-In English', 2),
(20, 'History ', 5),
(21, 'Physics', 3),
(22, 'Chemistry', 3),
(23, 'Biology', 3),
(24, 'Foods & Nutrition', 7),
(25, 'Tech. Drawing', 7),
(26, 'Music', 7),
(27, 'Metal Work', 7),
(28, 'Electrical', 7),
(29, 'Wood Work', 7),
(30, 'Commerce', 6),
(31, 'Account', 6),
(32, 'Economics', 6),
(33, 'Government', 5),
(34, 'F.Maths', 1),
(35, 'Animal Husbandry', 3),
(36, 'Data Processing', 1),
(37, 'ICT', 1),
(38, 'Civics', 5),
(39, 'Fine Arts', 7),
(40, 'Cat. Craft', 7),
(41, 'Paint & Decor', 7),
(42, 'Chinese', 2),
(43, 'Basic Tech', 7);

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=23 ;

--
-- Dumping data for table `teachers_classes`
--

INSERT INTO `teachers_classes` (`teacher_class_id`, `employee_id`, `class_id`, `academic_year_id`, `created_at`, `updated_at`) VALUES
(1, 14, 4, 1, '2015-03-23 12:32:00', '2015-03-23 11:32:00'),
(2, 48, 3, 1, '2015-03-23 12:32:28', '2015-03-23 11:32:28'),
(3, 17, 2, 1, '2015-03-23 12:32:49', '2015-03-23 11:32:49'),
(4, 50, 1, 1, '2015-03-23 12:35:55', '2015-03-23 11:36:11'),
(5, 54, 5, 1, '2015-03-23 12:36:41', '2015-03-23 11:36:41'),
(6, 13, 7, 1, '2015-03-23 12:37:27', '2015-03-23 11:37:27'),
(7, 52, 10, 1, '2015-03-23 12:38:31', '2015-03-23 11:38:31'),
(8, 23, 9, 1, '2015-03-23 12:38:52', '2015-03-23 11:38:52'),
(9, 44, 13, 1, '2015-03-23 12:43:15', '2015-03-23 11:43:15'),
(10, 30, 14, 1, '2015-03-23 12:43:34', '2015-03-23 11:43:34'),
(11, 43, 12, 1, '2015-03-23 12:44:30', '2015-03-23 11:44:30'),
(12, 46, 11, 1, '2015-03-23 12:44:57', '2015-03-23 11:44:57'),
(13, 53, 15, 1, '2015-03-23 12:45:16', '2015-03-23 11:45:21'),
(14, 62, 20, 1, '2015-03-23 12:53:48', '2015-03-23 11:53:48'),
(15, 38, 19, 1, '2015-03-23 12:54:56', '2015-03-23 11:54:56'),
(16, 32, 17, 1, '2015-03-23 12:55:08', '2015-03-23 11:55:08'),
(17, 60, 24, 1, '2015-03-23 12:58:14', '2015-03-23 11:58:14'),
(18, 42, 22, 1, '2015-03-23 12:58:35', '2015-03-23 11:58:35'),
(19, 40, 25, 1, '2015-03-23 12:58:52', '2015-03-23 11:58:52'),
(20, 16, 27, 1, '2015-03-23 12:59:54', '2015-03-23 11:59:54'),
(21, 59, 30, 1, '2015-03-23 01:00:14', '2015-03-23 12:00:14'),
(22, 65, 29, 1, '2015-03-24 01:14:31', '2015-03-24 12:14:31');

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
,`employee_name` varchar(202)
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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=515 ;

--
-- Dumping data for table `teachers_subjects`
--

INSERT INTO `teachers_subjects` (`teachers_subjects_id`, `employee_id`, `class_id`, `subject_classlevel_id`, `assign_date`) VALUES
(1, 45, 2, 150, '2015-03-23 01:03:53'),
(2, 45, 1, 150, '2015-03-23 01:04:11'),
(3, 45, 5, 150, '2015-03-23 01:04:19'),
(4, 45, 22, 36, '2015-03-23 01:04:45'),
(5, 45, 25, 36, '2015-03-23 01:05:07'),
(6, 3, 2, 130, '2015-03-23 01:06:41'),
(7, 3, 7, 131, '2015-03-23 01:07:15'),
(8, 3, 11, 133, '2015-03-23 01:09:12'),
(9, 3, 12, 133, '2015-03-23 01:09:21'),
(10, 3, 17, 134, '2015-03-23 01:09:59'),
(11, 3, 22, 135, '2015-03-23 01:10:21'),
(12, 3, 27, 136, '2015-03-23 01:10:44'),
(13, 3, 1, 130, '2015-03-23 01:14:21'),
(14, 3, 5, 130, '2015-03-23 01:14:39'),
(15, 3, 17, 154, '2015-03-23 01:19:37'),
(16, 3, 22, 155, '2015-03-23 01:20:43'),
(17, 3, 27, 156, '2015-03-23 01:21:08'),
(18, 3, 20, 154, '2015-03-23 01:21:40'),
(19, 3, 30, 156, '2015-03-23 01:24:52'),
(20, 4, 22, 94, '2015-03-23 01:26:10'),
(21, 4, 24, 94, '2015-03-23 01:26:17'),
(22, 4, 25, 94, '2015-03-23 01:26:47'),
(23, 4, 27, 95, '2015-03-23 01:27:29'),
(24, 4, 29, 95, '2015-03-23 01:27:43'),
(25, 40, 17, 93, '2015-03-23 01:35:02'),
(26, 40, 19, 93, '2015-03-23 01:35:13'),
(27, 40, 20, 93, '2015-03-23 01:35:20'),
(28, 40, 7, 16, '2015-03-23 01:35:54'),
(29, 40, 9, 16, '2015-03-23 01:35:57'),
(30, 5, 1, 157, '2015-03-23 01:55:14'),
(31, 5, 2, 157, '2015-03-23 01:55:18'),
(32, 5, 3, 157, '2015-03-23 01:55:24'),
(33, 5, 4, 157, '2015-03-23 01:55:28'),
(34, 5, 5, 157, '2015-03-23 01:55:42'),
(35, 5, 22, 161, '2015-03-23 01:56:00'),
(36, 5, 24, 161, '2015-03-23 01:56:04'),
(37, 5, 25, 161, '2015-03-23 01:56:08'),
(38, 5, 27, 164, '2015-03-23 01:56:42'),
(39, 5, 29, 164, '2015-03-23 01:57:01'),
(40, 5, 30, 164, '2015-03-23 01:57:06'),
(41, 6, 19, 138, '2015-03-23 01:58:16'),
(42, 6, 30, 142, '2015-03-23 01:58:39'),
(43, 6, 17, 105, '2015-03-23 01:59:39'),
(44, 6, 19, 105, '2015-03-23 01:59:52'),
(45, 6, 24, 106, '2015-03-23 02:00:53'),
(46, 6, 27, 107, '2015-03-23 02:01:29'),
(47, 7, 17, 81, '2015-03-23 02:03:11'),
(48, 7, 22, 82, '2015-03-23 02:03:46'),
(49, 7, 27, 87, '2015-03-23 02:04:10'),
(50, 7, 29, 87, '2015-03-23 02:04:34'),
(51, 7, 30, 87, '2015-03-23 02:04:40'),
(52, 7, 24, 82, '2015-03-23 02:05:02'),
(53, 7, 25, 82, '2015-03-23 02:05:05'),
(54, 7, 19, 81, '2015-03-23 02:05:11'),
(55, 7, 20, 81, '2015-03-23 02:05:14'),
(56, 8, 3, 130, '2015-03-23 02:06:13'),
(57, 8, 4, 130, '2015-03-23 02:49:06'),
(58, 8, 9, 131, '2015-03-23 02:50:28'),
(59, 8, 10, 131, '2015-03-23 02:51:09'),
(60, 8, 13, 133, '2015-03-23 02:51:45'),
(61, 8, 19, 134, '2015-03-23 02:52:38'),
(62, 8, 24, 135, '2015-03-23 02:53:20'),
(63, 8, 15, 133, '2015-03-23 03:09:09'),
(64, 8, 14, 133, '2015-03-23 03:09:15'),
(65, 8, 29, 136, '2015-03-23 03:10:15'),
(66, 8, 19, 154, '2015-03-23 03:11:58'),
(67, 8, 24, 155, '2015-03-23 03:12:49'),
(68, 8, 29, 156, '2015-03-23 03:14:07'),
(69, 8, 25, 155, '2015-03-23 03:14:10'),
(70, 21, 29, 142, '2015-03-23 03:14:57'),
(71, 17, 2, 21, '2015-03-23 03:40:24'),
(72, 17, 1, 21, '2015-03-23 03:40:43'),
(73, 17, 3, 21, '2015-03-23 03:40:51'),
(74, 17, 4, 21, '2015-03-23 03:40:58'),
(75, 17, 5, 21, '2015-03-23 03:41:05'),
(76, 17, 27, 26, '2015-03-23 03:41:52'),
(77, 17, 29, 26, '2015-03-23 03:41:57'),
(78, 17, 30, 26, '2015-03-23 03:45:22'),
(79, 9, 1, 166, '2015-03-23 04:50:45'),
(80, 9, 2, 166, '2015-03-23 04:52:13'),
(81, 9, 7, 167, '2015-03-23 04:52:25'),
(82, 9, 11, 168, '2015-03-23 04:52:47'),
(83, 9, 12, 168, '2015-03-23 04:52:53'),
(84, 9, 15, 168, '2015-03-23 04:54:14'),
(85, 9, 17, 169, '2015-03-23 04:54:25'),
(86, 9, 20, 169, '2015-03-23 04:54:59'),
(87, 9, 22, 170, '2015-03-23 04:56:10'),
(88, 9, 27, 171, '2015-03-23 04:57:32'),
(89, 17, 1, 173, '2015-03-23 06:00:05'),
(90, 17, 2, 173, '2015-03-23 06:00:16'),
(91, 17, 3, 173, '2015-03-23 06:00:24'),
(92, 17, 4, 173, '2015-03-23 06:00:30'),
(93, 17, 5, 173, '2015-03-23 06:00:39'),
(94, 10, 1, 174, '2015-03-24 05:03:24'),
(95, 10, 2, 174, '2015-03-24 05:03:28'),
(96, 10, 3, 174, '2015-03-24 05:03:31'),
(97, 10, 4, 174, '2015-03-24 05:03:33'),
(98, 10, 5, 174, '2015-03-24 05:03:36'),
(99, 10, 17, 73, '2015-03-24 05:04:31'),
(100, 10, 19, 73, '2015-03-24 05:04:33'),
(101, 10, 20, 73, '2015-03-24 05:04:35'),
(102, 10, 22, 74, '2015-03-24 05:04:44'),
(103, 10, 24, 74, '2015-03-24 05:04:47'),
(104, 10, 25, 74, '2015-03-24 05:04:50'),
(105, 10, 27, 75, '2015-03-24 05:05:02'),
(106, 10, 29, 75, '2015-03-24 05:05:04'),
(107, 10, 30, 75, '2015-03-24 05:05:06'),
(108, 11, 3, 166, '2015-03-24 05:05:45'),
(109, 11, 4, 166, '2015-03-24 05:05:59'),
(110, 11, 9, 167, '2015-03-24 05:06:51'),
(111, 11, 13, 168, '2015-03-24 05:07:18'),
(112, 11, 14, 168, '2015-03-24 05:07:21'),
(113, 11, 10, 167, '2015-03-24 05:07:40'),
(114, 11, 5, 166, '2015-03-24 05:07:45'),
(115, 11, 19, 169, '2015-03-24 05:08:05'),
(116, 11, 24, 170, '2015-03-24 05:08:49'),
(117, 11, 25, 170, '2015-03-24 05:09:01'),
(118, 11, 29, 171, '2015-03-24 05:09:27'),
(119, 12, 17, 53, '2015-03-24 05:12:08'),
(120, 12, 27, 54, '2015-03-24 05:15:47'),
(121, 12, 22, 177, '2015-03-24 05:16:31'),
(122, 12, 20, 53, '2015-03-24 05:18:26'),
(123, 12, 12, 12, '2015-03-24 05:19:32'),
(124, 12, 11, 12, '2015-03-24 05:19:46'),
(125, 12, 7, 8, '2015-03-24 05:19:56'),
(126, 12, 10, 8, '2015-03-24 05:20:52'),
(127, 13, 12, 3, '2015-03-24 05:21:46'),
(128, 13, 11, 3, '2015-03-24 05:21:54'),
(129, 13, 27, 6, '2015-03-24 05:22:09'),
(130, 13, 17, 35, '2015-03-24 05:23:00'),
(131, 13, 20, 35, '2015-03-24 05:23:03'),
(132, 14, 22, 98, '2015-03-24 05:24:40'),
(133, 14, 24, 98, '2015-03-24 05:24:44'),
(134, 14, 25, 98, '2015-03-24 05:29:15'),
(135, 14, 3, 15, '2015-03-24 05:30:40'),
(136, 14, 10, 16, '2015-03-24 05:30:55'),
(137, 15, 5, 18, '2015-03-24 05:33:15'),
(138, 15, 1, 18, '2015-03-24 05:33:35'),
(139, 16, 1, 126, '2015-03-24 05:34:23'),
(140, 16, 5, 126, '2015-03-24 05:34:36'),
(141, 16, 11, 128, '2015-03-24 05:35:02'),
(142, 16, 12, 128, '2015-03-24 05:35:05'),
(143, 16, 13, 128, '2015-03-24 05:35:31'),
(144, 16, 14, 128, '2015-03-24 05:35:34'),
(145, 16, 15, 128, '2015-03-24 05:35:38'),
(146, 16, 22, 141, '2015-03-24 05:36:07'),
(147, 16, 24, 141, '2015-03-24 05:36:15'),
(148, 16, 25, 141, '2015-03-24 05:36:18'),
(149, 16, 27, 144, '2015-03-24 05:36:37'),
(150, 16, 29, 144, '2015-03-24 05:36:42'),
(151, 16, 30, 144, '2015-03-24 05:36:46'),
(152, 18, 27, 46, '2015-03-24 05:37:41'),
(153, 18, 29, 46, '2015-03-24 05:37:44'),
(154, 18, 30, 46, '2015-03-24 05:37:47'),
(155, 18, 22, 44, '2015-03-24 05:37:59'),
(156, 18, 24, 44, '2015-03-24 05:38:03'),
(157, 18, 25, 44, '2015-03-24 05:38:07'),
(158, 19, 17, 56, '2015-03-24 05:39:06'),
(159, 19, 20, 56, '2015-03-24 05:39:06'),
(160, 19, 27, 60, '2015-03-24 05:39:28'),
(161, 19, 29, 60, '2015-03-24 05:39:30'),
(162, 19, 17, 172, '2015-03-24 05:49:20'),
(163, 19, 19, 172, '2015-03-24 05:49:24'),
(164, 19, 20, 172, '2015-03-24 05:49:26'),
(165, 19, 22, 179, '2015-03-24 05:49:41'),
(166, 19, 24, 179, '2015-03-24 05:49:43'),
(167, 19, 25, 179, '2015-03-24 05:49:45'),
(168, 19, 27, 178, '2015-03-24 05:50:02'),
(169, 19, 29, 178, '2015-03-24 05:50:06'),
(170, 19, 30, 178, '2015-03-24 05:50:08'),
(171, 20, 3, 183, '2015-03-24 05:50:33'),
(172, 20, 4, 183, '2015-03-24 05:50:43'),
(173, 20, 1, 183, '2015-03-24 05:50:46'),
(174, 20, 5, 183, '2015-03-24 05:50:51'),
(175, 20, 9, 184, '2015-03-24 05:51:29'),
(176, 20, 10, 184, '2015-03-24 05:51:33'),
(177, 20, 13, 185, '2015-03-24 05:52:35'),
(178, 20, 14, 185, '2015-03-24 05:52:40'),
(179, 20, 15, 185, '2015-03-24 05:52:45'),
(180, 20, 19, 180, '2015-03-24 05:53:13'),
(181, 20, 19, 58, '2015-03-24 05:54:16'),
(182, 20, 24, 181, '2015-03-24 05:54:26'),
(183, 20, 24, 59, '2015-03-24 05:54:44'),
(184, 20, 29, 182, '2015-03-24 05:54:53'),
(185, 20, 29, 61, '2015-03-24 05:55:13'),
(186, 17, 1, 186, '2015-03-24 06:01:02'),
(187, 17, 2, 186, '2015-03-24 06:01:07'),
(188, 17, 3, 186, '2015-03-24 06:01:15'),
(189, 17, 4, 186, '2015-03-24 06:01:19'),
(190, 17, 5, 186, '2015-03-24 06:02:17'),
(191, 21, 3, 137, '2015-03-24 06:57:32'),
(192, 21, 4, 137, '2015-03-24 06:57:40'),
(193, 21, 17, 42, '2015-03-24 06:58:01'),
(194, 21, 19, 42, '2015-03-24 06:58:08'),
(195, 21, 20, 42, '2015-03-24 06:58:17'),
(196, 22, 3, 119, '2015-03-24 06:59:16'),
(197, 22, 4, 119, '2015-03-24 06:59:19'),
(198, 22, 9, 120, '2015-03-24 06:59:34'),
(199, 22, 10, 120, '2015-03-24 06:59:37'),
(200, 22, 13, 121, '2015-03-24 07:00:03'),
(201, 22, 14, 121, '2015-03-24 07:00:05'),
(202, 22, 19, 123, '2015-03-24 07:00:28'),
(203, 22, 20, 123, '2015-03-24 07:00:30'),
(204, 22, 24, 124, '2015-03-24 07:01:29'),
(205, 22, 29, 127, '2015-03-24 07:01:42'),
(206, 23, 13, 3, '2015-03-24 07:02:31'),
(207, 23, 14, 3, '2015-03-24 07:02:33'),
(208, 23, 15, 3, '2015-03-24 07:03:09'),
(209, 23, 29, 37, '2015-03-24 07:07:18'),
(210, 23, 29, 6, '2015-03-24 07:09:37'),
(211, 24, 10, 9, '2015-03-24 07:54:57'),
(212, 52, 20, 24, '2015-03-24 07:57:12'),
(213, 24, 20, 138, '2015-03-24 07:57:31'),
(214, 24, 24, 140, '2015-03-24 07:58:16'),
(215, 24, 29, 107, '2015-03-24 08:01:10'),
(216, 25, 27, 34, '2015-03-24 08:01:45'),
(217, 25, 29, 34, '2015-03-24 08:01:50'),
(218, 25, 30, 34, '2015-03-24 08:01:52'),
(219, 25, 22, 31, '2015-03-24 08:02:18'),
(220, 25, 24, 31, '2015-03-24 08:02:23'),
(221, 25, 25, 31, '2015-03-24 08:02:44'),
(222, 25, 7, 20, '2015-03-24 08:04:44'),
(223, 25, 9, 20, '2015-03-24 08:04:47'),
(224, 25, 10, 20, '2015-03-24 08:05:03'),
(225, 25, 15, 19, '2015-03-24 08:05:31'),
(226, 26, 1, 64, '2015-03-24 08:06:06'),
(227, 26, 2, 64, '2015-03-24 08:06:11'),
(228, 26, 3, 64, '2015-03-24 08:06:13'),
(229, 26, 4, 64, '2015-03-24 08:06:17'),
(230, 26, 5, 64, '2015-03-24 08:06:19'),
(231, 26, 7, 149, '2015-03-24 08:10:16'),
(232, 26, 9, 149, '2015-03-24 08:10:20'),
(233, 26, 10, 149, '2015-03-24 08:10:22'),
(234, 26, 11, 66, '2015-03-24 08:10:40'),
(235, 26, 12, 66, '2015-03-24 08:11:01'),
(236, 26, 13, 66, '2015-03-24 08:11:03'),
(237, 26, 14, 66, '2015-03-24 08:11:06'),
(238, 26, 15, 66, '2015-03-24 08:11:09'),
(239, 27, 2, 183, '2015-03-24 08:12:49'),
(240, 27, 7, 184, '2015-03-24 08:13:02'),
(241, 27, 12, 185, '2015-03-24 08:15:47'),
(242, 27, 11, 185, '2015-03-24 08:15:55'),
(243, 27, 17, 58, '2015-03-24 08:18:22'),
(244, 27, 22, 59, '2015-03-24 08:18:43'),
(245, 27, 25, 59, '2015-03-24 08:20:08'),
(246, 27, 20, 58, '2015-03-24 08:20:19'),
(247, 27, 17, 180, '2015-03-24 08:21:45'),
(248, 27, 20, 180, '2015-03-24 08:21:54'),
(249, 27, 22, 181, '2015-03-24 08:22:43'),
(250, 27, 25, 181, '2015-03-24 08:22:51'),
(251, 27, 27, 182, '2015-03-24 08:23:15'),
(252, 28, 5, 119, '2015-03-24 08:25:09'),
(253, 28, 15, 121, '2015-03-24 08:26:34'),
(254, 28, 25, 124, '2015-03-24 08:27:41'),
(255, 28, 22, 124, '2015-03-24 08:27:59'),
(256, 28, 27, 127, '2015-03-24 08:28:16'),
(257, 29, 1, 137, '2015-03-24 08:33:14'),
(258, 29, 5, 137, '2015-03-24 08:35:41'),
(259, 59, 24, 5, '2015-03-24 09:43:01'),
(260, 59, 25, 5, '2015-03-24 09:43:07'),
(261, 59, 24, 36, '2015-03-24 09:43:29'),
(262, 59, 4, 150, '2015-03-24 09:46:00'),
(263, 19, 1, 143, '2015-03-24 11:15:41'),
(264, 19, 2, 143, '2015-03-24 11:15:55'),
(265, 19, 3, 143, '2015-03-24 11:16:03'),
(266, 19, 4, 143, '2015-03-24 11:16:09'),
(267, 19, 5, 143, '2015-03-24 11:16:15'),
(268, 30, 11, 110, '2015-03-24 11:16:57'),
(269, 30, 12, 110, '2015-03-24 11:17:05'),
(270, 30, 13, 110, '2015-03-24 11:17:12'),
(271, 30, 14, 110, '2015-03-24 11:17:25'),
(272, 30, 15, 110, '2015-03-24 11:17:36'),
(273, 30, 27, 122, '2015-03-24 11:19:00'),
(274, 30, 29, 122, '2015-03-24 11:19:43'),
(275, 30, 22, 118, '2015-03-24 11:21:04'),
(276, 30, 24, 118, '2015-03-24 11:21:12'),
(277, 30, 25, 118, '2015-03-24 11:21:20'),
(278, 53, 9, 10, '2015-03-24 11:37:58'),
(279, 53, 10, 10, '2015-03-24 11:38:04'),
(280, 53, 19, 4, '2015-03-24 11:38:31'),
(281, 53, 19, 35, '2015-03-24 11:38:46'),
(282, 52, 7, 22, '2015-03-24 11:41:08'),
(283, 52, 9, 22, '2015-03-24 11:41:10'),
(284, 52, 10, 22, '2015-03-24 11:41:13'),
(285, 52, 17, 24, '2015-03-24 11:43:32'),
(286, 52, 19, 24, '2015-03-24 11:43:33'),
(287, 30, 11, 187, '2015-03-24 00:09:38'),
(288, 30, 12, 187, '2015-03-24 00:09:46'),
(289, 30, 13, 187, '2015-03-24 00:09:52'),
(290, 30, 14, 187, '2015-03-24 00:09:54'),
(291, 30, 15, 187, '2015-03-24 00:09:56'),
(292, 29, 12, 11, '2015-03-24 00:22:44'),
(293, 29, 11, 11, '2015-03-24 00:23:13'),
(294, 6, 27, 142, '2015-03-24 00:26:24'),
(295, 29, 30, 107, '2015-03-24 00:28:45'),
(296, 32, 2, 15, '2015-03-24 00:31:12'),
(297, 32, 1, 15, '2015-03-24 00:31:32'),
(298, 32, 5, 15, '2015-03-24 00:31:47'),
(299, 14, 4, 15, '2015-03-24 00:32:45'),
(300, 32, 11, 17, '2015-03-24 00:39:27'),
(301, 32, 12, 17, '2015-03-24 00:40:19'),
(302, 32, 13, 17, '2015-03-24 00:40:28'),
(303, 32, 14, 17, '2015-03-24 00:40:39'),
(304, 32, 15, 17, '2015-03-24 00:42:08'),
(305, 33, 11, 159, '2015-03-24 00:43:25'),
(306, 33, 12, 159, '2015-03-24 00:43:39'),
(307, 33, 13, 159, '2015-03-24 00:43:47'),
(308, 33, 14, 159, '2015-03-24 00:44:07'),
(309, 33, 15, 159, '2015-03-24 00:44:16'),
(310, 33, 17, 160, '2015-03-24 00:44:37'),
(311, 33, 19, 160, '2015-03-24 00:44:41'),
(312, 33, 20, 160, '2015-03-24 00:44:50'),
(313, 33, 17, 163, '2015-03-24 00:45:13'),
(314, 33, 19, 163, '2015-03-24 00:45:28'),
(315, 33, 20, 163, '2015-03-24 00:45:42'),
(316, 34, 7, 175, '2015-03-24 00:52:55'),
(317, 34, 9, 175, '2015-03-24 00:52:59'),
(318, 34, 10, 175, '2015-03-24 00:53:02'),
(319, 34, 17, 62, '2015-03-24 02:56:16'),
(320, 34, 19, 62, '2015-03-24 02:56:20'),
(321, 34, 20, 62, '2015-03-24 02:56:28'),
(322, 35, 22, 101, '2015-03-24 02:59:58'),
(323, 35, 24, 101, '2015-03-24 03:00:25'),
(324, 35, 25, 101, '2015-03-24 03:00:38'),
(325, 35, 17, 100, '2015-03-24 03:02:59'),
(326, 35, 19, 100, '2015-03-24 03:03:04'),
(327, 35, 20, 100, '2015-03-24 03:03:10'),
(328, 35, 27, 103, '2015-03-24 03:04:32'),
(329, 35, 29, 103, '2015-03-24 03:06:21'),
(330, 35, 30, 103, '2015-03-24 03:06:35'),
(331, 36, 19, 53, '2015-03-25 11:09:28'),
(332, 36, 24, 177, '2015-03-25 11:15:07'),
(333, 36, 25, 177, '2015-03-25 11:15:09'),
(334, 36, 13, 12, '2015-03-25 11:16:08'),
(335, 36, 14, 12, '2015-03-25 11:16:14'),
(336, 36, 15, 12, '2015-03-25 11:16:16'),
(337, 39, 11, 176, '2015-03-25 11:20:03'),
(338, 39, 12, 176, '2015-03-25 11:20:06'),
(339, 39, 13, 176, '2015-03-25 11:20:17'),
(340, 39, 14, 176, '2015-03-25 11:20:18'),
(341, 39, 15, 176, '2015-03-25 11:20:26'),
(342, 39, 22, 63, '2015-03-25 11:21:07'),
(343, 39, 24, 63, '2015-03-25 11:21:12'),
(344, 39, 25, 63, '2015-03-25 11:21:15'),
(345, 39, 27, 65, '2015-03-25 11:21:46'),
(346, 39, 29, 65, '2015-03-25 11:21:49'),
(347, 39, 30, 65, '2015-03-25 11:21:53'),
(348, 41, 27, 190, '2015-03-25 11:26:00'),
(349, 41, 22, 189, '2015-03-25 11:26:47'),
(350, 41, 17, 188, '2015-03-25 11:27:08'),
(351, 41, 20, 188, '2015-03-25 11:27:14'),
(352, 41, 11, 28, '2015-03-25 11:27:29'),
(353, 41, 12, 28, '2015-03-25 11:27:31'),
(354, 41, 7, 148, '2015-03-25 11:28:05'),
(355, 41, 10, 148, '2015-03-25 11:28:11'),
(356, 42, 22, 25, '2015-03-25 11:29:04'),
(357, 42, 24, 25, '2015-03-25 11:29:09'),
(358, 42, 25, 25, '2015-03-25 11:29:16'),
(359, 42, 11, 23, '2015-03-25 11:29:46'),
(360, 42, 12, 23, '2015-03-25 11:29:53'),
(361, 42, 13, 23, '2015-03-25 11:29:57'),
(362, 42, 14, 23, '2015-03-25 11:30:03'),
(363, 42, 15, 23, '2015-03-25 11:30:10'),
(364, 43, 20, 105, '2015-03-25 11:30:40'),
(365, 43, 25, 106, '2015-03-25 11:30:59'),
(366, 43, 2, 137, '2015-03-25 11:31:17'),
(367, 43, 9, 9, '2015-03-25 11:31:39'),
(368, 44, 2, 108, '2015-03-25 11:32:57'),
(369, 44, 4, 108, '2015-03-25 11:33:06'),
(370, 44, 7, 109, '2015-03-25 11:33:28'),
(371, 44, 9, 109, '2015-03-25 11:33:38'),
(372, 44, 10, 109, '2015-03-25 11:33:49'),
(373, 44, 17, 111, '2015-03-25 11:34:36'),
(374, 44, 19, 111, '2015-03-25 11:34:41'),
(375, 44, 20, 111, '2015-03-25 11:34:49'),
(376, 46, 27, 99, '2015-03-25 11:15:59'),
(377, 46, 29, 99, '2015-03-25 11:16:15'),
(378, 46, 30, 99, '2015-03-25 11:16:20'),
(379, 46, 17, 97, '2015-03-25 11:16:56'),
(380, 46, 19, 97, '2015-03-25 11:17:00'),
(381, 46, 20, 97, '2015-03-25 11:17:05'),
(382, 47, 17, 30, '2015-03-25 11:18:09'),
(383, 47, 19, 30, '2015-03-25 11:18:19'),
(384, 47, 20, 30, '2015-03-25 11:18:23'),
(385, 47, 2, 18, '2015-03-25 11:19:40'),
(386, 47, 4, 18, '2015-03-25 11:19:57'),
(387, 47, 11, 19, '2015-03-25 11:22:17'),
(388, 47, 12, 19, '2015-03-25 11:22:24'),
(389, 47, 13, 19, '2015-03-25 11:22:32'),
(390, 47, 14, 19, '2015-03-25 11:22:44'),
(391, 48, 13, 11, '2015-03-25 11:23:10'),
(392, 48, 14, 11, '2015-03-25 11:23:22'),
(393, 48, 15, 11, '2015-03-25 11:23:37'),
(394, 48, 17, 138, '2015-03-25 11:25:18'),
(395, 50, 17, 48, '2015-03-25 11:26:30'),
(396, 50, 20, 48, '2015-03-25 11:26:42'),
(397, 50, 24, 49, '2015-03-25 11:30:03'),
(398, 50, 25, 49, '2015-03-25 11:30:04'),
(399, 50, 2, 7, '2015-03-25 11:32:27'),
(400, 50, 5, 7, '2015-03-25 11:32:38'),
(401, 50, 1, 7, '2015-03-25 11:32:50'),
(402, 51, 7, 10, '2015-03-25 11:34:02'),
(403, 51, 17, 4, '2015-03-25 11:34:32'),
(404, 51, 20, 4, '2015-03-25 11:34:36'),
(405, 51, 27, 37, '2015-03-25 11:35:09'),
(406, 51, 30, 37, '2015-03-25 11:35:21'),
(407, 54, 7, 145, '2015-03-25 11:36:08'),
(408, 54, 9, 145, '2015-03-25 11:36:15'),
(409, 54, 10, 145, '2015-03-25 11:36:21'),
(410, 54, 11, 146, '2015-03-25 11:36:44'),
(411, 54, 12, 146, '2015-03-25 11:36:54'),
(412, 54, 13, 146, '2015-03-25 11:37:04'),
(413, 54, 14, 146, '2015-03-25 11:37:10'),
(414, 54, 15, 146, '2015-03-25 11:37:19'),
(415, 54, 19, 56, '2015-03-25 11:37:37'),
(416, 55, 2, 126, '2015-03-25 11:38:52'),
(417, 55, 4, 126, '2015-03-25 11:38:58'),
(418, 55, 7, 139, '2015-03-25 11:39:40'),
(419, 55, 9, 139, '2015-03-25 11:39:41'),
(420, 55, 10, 139, '2015-03-25 11:39:51'),
(421, 55, 17, 129, '2015-03-25 11:41:30'),
(422, 55, 19, 129, '2015-03-25 11:41:45'),
(423, 56, 27, 51, '2015-03-25 11:42:54'),
(424, 56, 29, 51, '2015-03-25 11:43:17'),
(425, 56, 19, 48, '2015-03-25 11:43:49'),
(426, 56, 22, 49, '2015-03-25 11:44:08'),
(427, 56, 4, 7, '2015-03-25 11:44:38'),
(428, 56, 9, 8, '2015-03-25 11:45:02'),
(429, 57, 7, 158, '2015-03-25 11:45:41'),
(430, 57, 9, 158, '2015-03-25 11:45:46'),
(431, 57, 10, 158, '2015-03-25 11:46:02'),
(432, 57, 27, 162, '2015-03-25 11:46:35'),
(433, 57, 29, 162, '2015-03-25 11:46:41'),
(434, 57, 30, 162, '2015-03-25 11:46:47'),
(435, 57, 22, 165, '2015-03-25 11:47:16'),
(436, 57, 24, 165, '2015-03-25 11:47:28'),
(437, 57, 25, 165, '2015-03-25 11:47:38'),
(438, 58, 1, 27, '2015-03-25 11:48:38'),
(439, 58, 5, 27, '2015-03-25 11:48:51'),
(440, 58, 4, 27, '2015-03-25 11:49:08'),
(441, 58, 9, 148, '2015-03-25 11:49:45'),
(442, 58, 13, 28, '2015-03-25 11:50:57'),
(443, 58, 14, 28, '2015-03-25 11:51:17'),
(444, 58, 19, 188, '2015-03-25 11:51:59'),
(445, 58, 24, 189, '2015-03-25 11:53:15'),
(446, 58, 29, 190, '2015-03-25 11:55:30'),
(447, 60, 7, 9, '2015-03-25 11:56:23'),
(448, 60, 22, 140, '2015-03-25 11:56:44'),
(449, 60, 25, 140, '2015-03-25 11:56:49'),
(450, 60, 22, 106, '2015-03-25 11:57:03'),
(451, 61, 1, 112, '2015-03-25 11:57:44'),
(452, 61, 2, 112, '2015-03-25 11:57:50'),
(453, 61, 5, 112, '2015-03-25 11:57:55'),
(454, 63, 4, 112, '2015-03-25 00:00:41'),
(455, 61, 7, 113, '2015-03-25 00:12:12'),
(456, 63, 9, 113, '2015-03-25 00:13:48'),
(457, 63, 13, 114, '2015-03-25 00:15:35'),
(458, 63, 14, 114, '2015-03-25 00:18:43'),
(459, 63, 15, 114, '2015-03-25 00:18:58'),
(460, 61, 11, 114, '2015-03-25 00:19:59'),
(461, 61, 12, 114, '2015-03-25 00:20:07'),
(462, 61, 17, 115, '2015-03-25 00:20:39'),
(463, 63, 19, 115, '2015-03-25 00:20:45'),
(464, 61, 22, 116, '2015-03-25 00:26:34'),
(465, 63, 24, 116, '2015-03-25 00:26:40'),
(466, 61, 25, 116, '2015-03-25 00:26:55'),
(467, 61, 27, 117, '2015-03-25 00:27:40'),
(468, 63, 29, 117, '2015-03-25 00:27:45'),
(469, 62, 27, 91, '2015-03-25 00:29:01'),
(470, 62, 29, 91, '2015-03-25 00:29:05'),
(471, 62, 30, 91, '2015-03-25 00:29:09'),
(472, 62, 22, 88, '2015-03-25 00:29:22'),
(473, 62, 24, 88, '2015-03-25 00:29:30'),
(474, 62, 25, 88, '2015-03-25 00:29:34'),
(475, 62, 17, 86, '2015-03-25 00:30:02'),
(476, 62, 19, 86, '2015-03-25 00:30:05'),
(477, 62, 20, 86, '2015-03-25 00:30:20'),
(478, 62, 11, 78, '2015-03-25 00:30:34'),
(479, 62, 12, 78, '2015-03-25 00:30:37'),
(480, 62, 13, 78, '2015-03-25 00:30:41'),
(481, 62, 14, 78, '2015-03-25 00:30:49'),
(482, 62, 15, 78, '2015-03-25 00:30:52'),
(483, 62, 7, 102, '2015-03-25 00:31:05'),
(484, 62, 9, 102, '2015-03-25 00:31:09'),
(485, 62, 10, 102, '2015-03-25 00:31:15'),
(486, 62, 1, 76, '2015-03-25 00:31:27'),
(487, 62, 2, 76, '2015-03-25 00:31:31'),
(488, 62, 4, 76, '2015-03-25 00:31:37'),
(489, 62, 5, 76, '2015-03-25 00:31:44'),
(490, 67, 17, 194, '2015-03-26 08:40:05'),
(491, 67, 19, 194, '2015-03-26 08:40:11'),
(492, 67, 20, 194, '2015-03-26 08:40:15'),
(493, 67, 1, 191, '2015-03-26 08:40:43'),
(494, 67, 2, 191, '2015-03-26 08:40:47'),
(495, 67, 4, 191, '2015-03-26 08:40:52'),
(496, 67, 5, 191, '2015-03-26 08:40:57'),
(497, 67, 7, 192, '2015-03-26 08:41:16'),
(498, 67, 9, 192, '2015-03-26 08:41:20'),
(499, 67, 10, 192, '2015-03-26 08:41:26'),
(500, 67, 11, 193, '2015-03-26 08:42:02'),
(501, 67, 12, 193, '2015-03-26 08:42:07'),
(502, 67, 13, 193, '2015-03-26 08:42:12'),
(503, 67, 14, 193, '2015-03-26 08:42:18'),
(504, 67, 15, 193, '2015-03-26 08:42:23'),
(505, 67, 22, 195, '2015-03-26 08:42:43'),
(506, 67, 24, 195, '2015-03-26 08:42:51'),
(507, 67, 25, 195, '2015-03-26 08:42:56'),
(508, 58, 5, 196, '2015-03-26 10:11:44'),
(509, 58, 1, 196, '2015-03-26 10:11:49'),
(510, 41, 2, 196, '2015-03-26 10:11:54'),
(511, 58, 4, 196, '2015-03-26 10:11:58'),
(512, 58, 9, 197, '2015-03-26 10:27:10'),
(513, 41, 10, 197, '2015-03-26 10:27:16'),
(514, 41, 7, 197, '2015-03-26 10:27:26');

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
,`employee_name` varchar(202)
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
  `group_alias` varchar(30) NOT NULL DEFAULT 'PAR_USERS'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=8 ;

--
-- Dumping data for table `user_roles`
--

INSERT INTO `user_roles` (`user_role_id`, `user_role`, `group_alias`) VALUES
(1, 'Parent', 'PAR_USERS'),
(3, 'Staff', 'STF_USERS'),
(4, 'ICT', 'ICT_USERS'),
(5, 'Vice Principal', 'ADM_USERS'),
(6, 'Principal', 'ADM_USERS'),
(7, 'Super Admin', 'ADM_USERS');

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=343 ;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `password`, `display_name`, `type_id`, `image_url`, `user_role_id`, `group_alias`, `status_id`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'smartedu', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'SmartEdu App', 0, NULL, 7, 'ADM_USERS', 1, 1, '2015-03-22 04:36:45', '2015-03-26 08:00:29'),
(2, 'PAR0001', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'STANLEY OGBUCHI', 1, 'sponsors/1.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 02:11:34', '2015-03-23 11:17:45'),
(3, 'STF0001', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'Dotun Kudaisi ', 1, 'employees/1.png', 7, 'ADM_USERS', 1, 1, '2015-03-23 11:09:03', '2015-03-26 08:00:22'),
(5, 'STF0003', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'J. Abikoye ', 3, 'employees/3.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:40:35', '2015-03-26 07:59:53'),
(6, 'STF0004', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'M. ADEGOKE', 4, 'employees/4.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:42:34', '2015-03-26 07:59:53'),
(7, 'STF0005', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'B. ADEYEMI', 5, 'employees/5.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:47:32', '2015-03-26 07:59:53'),
(8, 'STF0006', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'S. ADISA', 6, 'employees/6.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:48:42', '2015-03-26 07:59:53'),
(9, 'STF0007', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'A. AIGBOMIAN', 7, 'employees/7.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:49:44', '2015-03-26 07:59:53'),
(10, 'STF0008', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'G. AJAYI', 8, 'employees/8.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:53:19', '2015-03-26 07:59:53'),
(11, 'PAR0002', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR ADENIRAN', 2, 'sponsors/2.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 06:57:19', '2015-03-23 11:17:45'),
(12, 'STF0009', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'B. AKINROLABU', 9, 'employees/9.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:57:44', '2015-03-26 07:59:53'),
(13, 'STF0010', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'D. AKINYEMI', 10, 'employees/10.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:58:39', '2015-03-26 07:59:53'),
(14, 'PAR0003', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR ATUNRASE', 3, 'sponsors/3.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 06:58:57', '2015-03-23 11:17:45'),
(15, 'STF0011', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'Z. ALIU', 11, 'employees/11.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:59:28', '2015-03-26 07:59:53'),
(16, 'PAR0004', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR BAIYEKUSI', 4, 'sponsors/4.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:00:53', '2015-03-23 11:17:45'),
(17, 'STF0012', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'A. ANJORIN', 12, 'employees/12.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:00:59', '2015-03-26 07:59:53'),
(18, 'STF0013', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'O.ARAOYE', 13, 'employees/13.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:11:12', '2015-03-23 12:00:52'),
(19, 'PAR0005', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR BAKRE', 5, 'sponsors/5.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:02:41', '2015-03-23 11:17:45'),
(20, 'STF0014', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'A. AWOGBADE', 14, 'employees/14.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:23:50', '2015-03-23 12:02:04'),
(21, 'PAR0006', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR BALOGUN', 6, 'sponsors/6.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:04:50', '2015-03-23 11:17:45'),
(22, 'STF0015', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'ADERONKE AYEGBUSI', 15, 'employees/15.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:05:29', '2015-03-26 07:59:53'),
(23, 'STF0016', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'B. AZEEZ', 16, 'employees/16.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:17:09', '2015-03-23 12:02:46'),
(24, 'STF0017', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'D. AZIAKA', 17, 'employees/17.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 04:50:23', '2015-03-26 07:59:53'),
(25, 'STF0018', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'A. BABALOLA', 18, 'employees/18.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:08:50', '2015-03-26 07:59:53'),
(26, 'PAR0007', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR BAYOKO', 7, 'sponsors/7.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:12:26', '2015-03-23 11:17:45'),
(27, 'STF0019', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'F. BABATOPE', 19, 'employees/19.jpg', 3, 'STF_USERS', 1, 1, '2015-03-19 07:12:59', '2015-04-08 11:20:57'),
(28, 'STF0020', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'BADERIN ', 20, 'employees/20.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:14:15', '2015-03-26 07:59:53'),
(29, 'STF0021', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'INCREASE BETIKU', 21, 'employees/21.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:14:58', '2015-03-26 07:59:53'),
(30, 'STF0022', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'B. DADA', 22, 'employees/22.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:17:57', '2015-03-26 07:59:53'),
(31, 'PAR0008', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR EGBEDEYI', 8, 'sponsors/8.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:20:00', '2015-03-23 11:17:45'),
(32, 'PAR0009', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR HENRY-NKEKI', 9, 'sponsors/9.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:36:10', '2015-03-23 11:17:45'),
(33, 'STF0023', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'M. EKPUH', 23, 'employees/23.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:25:45', '2015-03-23 12:14:46'),
(34, 'PAR0010', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR IBILOLA', 10, 'sponsors/10.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:37:47', '2015-03-23 11:17:45'),
(35, 'STF0024', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'E. EKUNBOYEJO', 24, 'employees/24.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:37:49', '2015-03-26 07:59:53'),
(36, 'STF0025', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'L. EWERE', 25, 'employees/25.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:39:13', '2015-03-26 07:59:53'),
(37, 'STF0026', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'E.FAKOLUJO', 26, 'employees/26.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:39:46', '2015-03-26 07:59:53'),
(38, 'PAR0011', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR NICK-IBITOYE', 11, 'sponsors/11.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:42:44', '2015-03-23 11:17:45'),
(39, 'STF0027', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'J. FAMAKINWA', 27, 'employees/27.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:46:36', '2015-03-26 07:59:53'),
(40, 'PAR0012', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR NKUME-ANYIGOR', 12, 'sponsors/12.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:46:39', '2015-03-23 11:17:45'),
(41, 'STF0028', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'ABIODUN GBADAMOSI', 28, 'employees/28.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:50:51', '2015-03-26 07:59:53'),
(42, 'PAR0013', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR OFOEGBUNAM', 13, 'sponsors/13.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:51:38', '2015-03-23 11:17:45'),
(43, 'STF0029', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'M. IBITAYO', 29, 'employees/29.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:53:51', '2015-03-26 07:59:53'),
(44, 'PAR0014', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR OGHOORE', 14, 'sponsors/14.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:55:38', '2015-03-23 11:17:45'),
(45, 'STF0030', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'N. IKEME', 30, 'employees/30.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-24 12:22:36', '2015-03-26 07:59:53'),
(46, 'PAR0015', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR OLAGUNJU', 15, 'sponsors/15.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:57:44', '2015-03-23 11:17:45'),
(48, 'PAR0016', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR OLATUNBOSUN', 16, 'sponsors/16.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 08:01:47', '2015-03-23 11:17:45'),
(49, 'STF0032', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'F. JOSEPH', 32, 'employees/32.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:16:03', '2015-03-23 12:14:46'),
(50, 'PAR0017', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MR YUSUF', 17, 'sponsors/17.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 08:03:41', '2015-03-23 11:17:45'),
(51, 'STF0033', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'L. KOLORUKO', 33, 'employees/33.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 08:32:09', '2015-03-26 07:59:53'),
(52, 'STF0034', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'A. LIADI', 34, 'employees/34.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 08:10:38', '2015-03-26 07:59:53'),
(53, 'STF0035', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OLANREWAJU MEMUD', 35, 'employees/35.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 08:11:09', '2015-03-26 07:59:53'),
(54, 'STF0036', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'T. MUDASIRU', 36, 'employees/36.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 08:15:50', '2015-03-26 07:59:53'),
(55, 'STF0031', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'F.A. ', 31, 'employees/31.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 08:16:26', '2015-03-26 07:59:53'),
(57, 'STF0038', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'F. NOAH', 38, 'employees/38.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:27:18', '2015-03-23 12:14:46'),
(58, 'STF0039', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'D. NOSIKE', 39, 'employees/39.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 12:00:40', '2015-03-26 07:59:53'),
(59, 'STF0040', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', '. ADEOGUN', 40, 'employees/40.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:59:22', '2015-03-23 12:14:46'),
(60, 'STF0041', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'J. NWANI', 41, 'employees/41.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:09:36', '2015-03-26 07:59:53'),
(61, 'STF0042', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'U. NWANKWO', 42, 'employees/42.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:16:32', '2015-03-23 12:14:46'),
(62, 'STF0043', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'B. OBAJINMI,', 43, 'employees/43.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:14:57', '2015-03-23 12:14:46'),
(63, 'STF0044', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'C. OBIANO', 44, 'employees/44.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-24 01:21:59', '2015-03-24 12:21:59'),
(64, 'STF0045', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'A. OGUNBOWALE', 45, 'employees/45.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:15:41', '2015-03-26 07:59:53'),
(65, 'STF0046', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'M. OGUNLEYE', 46, 'employees/46.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:15:20', '2015-03-23 12:14:46'),
(66, 'STF0047', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'M. OGUNSOLA', 47, 'employees/47.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:24:14', '2015-03-26 07:59:53'),
(67, 'STF0048', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'A. OJENIYI', 48, 'employees/48.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:25:04', '2015-03-23 12:14:46'),
(68, 'STF0049', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'S. OJETUNDE', 49, 'employees/49.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:27:16', '2015-03-26 07:59:53'),
(69, 'STF0050', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'T. OJO', 50, 'employees/50.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:20:27', '2015-03-23 12:14:46'),
(70, 'STF0051', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'B. OKECHUKWU-OMOLUABI', 51, 'employees/51.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:30:43', '2015-03-26 07:59:53'),
(71, 'STF0052', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'I. OKINI,', 52, 'employees/52.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:20:58', '2015-03-23 12:14:46'),
(72, 'STF0053', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'O. OLAKANLE', 53, 'employees/53.jpg', 4, 'ICT_USERS', 1, 0, '2015-03-23 02:13:32', '2015-03-23 13:32:33'),
(73, 'STF0054', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'T. OLATUNDE', 54, 'employees/54.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:19:00', '2015-03-23 12:14:46'),
(74, 'STF0055', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'O. OLAWOLE', 55, 'employees/55.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:47:53', '2015-03-26 07:59:53'),
(75, 'STF0056', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'K. ORIMOLADE', 56, 'employees/56.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:48:44', '2015-03-26 07:59:53'),
(76, 'STF0057', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'A. OWADOYE', 57, 'employees/57.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:49:38', '2015-03-26 07:59:53'),
(77, 'STF0058', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'T. SOKOYA', 58, 'employees/58.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:50:21', '2015-03-26 07:59:53'),
(78, 'STF0059', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'S. TEMURU', 59, 'employees/59.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:23:10', '2015-03-23 12:14:46'),
(79, 'STF0060', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'O. UADEMEVBO', 60, 'employees/60.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:27:44', '2015-03-23 12:14:46'),
(80, 'STF0061', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'L. UDOKPORO', 61, 'employees/61.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:55:54', '2015-03-26 07:59:53'),
(81, 'STF0062', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'A. UMAR-MUHAMMED,', 62, 'employees/62.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:22:39', '2015-03-23 12:14:46'),
(82, 'STF0063', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'G. USHIE', 63, 'employees/63.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:59:08', '2015-03-26 07:59:53'),
(83, 'STF0064', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'EMMANUEL Okafor', 64, 'employees/64.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-22 02:15:37', '2015-03-26 07:59:53'),
(91, 'STF0065', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', '. Salau', 65, 'employees/65.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-24 01:16:39', '2015-03-24 12:16:39'),
(92, 'PAR0025', '$2a$10$XEGtrkPpds9LoNDuUYY1Ke8tZ6BK6MWJJLoNH93mSVYsRRAD43rYi', 'OLADAPO AJAYI', 25, 'sponsors/25.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 10:17:45', '2015-03-24 09:17:45'),
(93, 'PAR0026', '$2a$10$H3h14rHKrZA4uIdTCt57AeEkxzUDMZOEfeN913I0dxoK.UhA9cb7W', 'OPEYEMI', 26, 'sponsors/26.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 10:23:45', '2015-03-24 09:23:46'),
(96, 'PAR0029', '$2a$10$lyPMJZZxKVLYidIubyQKyON9MtaL5hDCr.I18/cYP37ZMJ08Daevu', 'ADEGBOYEGA WILLIAMS', 29, 'sponsors/29.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 10:49:42', '2015-03-24 09:49:42'),
(97, 'PAR0030', '$2a$10$EMJz6SeQCFpeM.pAuyzSD.Vw4auF53bTGYHl5L4e6nhGEfTokJLji', 'IFEOLUWA ADEALU', 30, 'sponsors/30.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-24 11:08:11', '2015-03-24 10:08:11'),
(99, 'PAR0032', '$2a$10$3Rxvow0am4ntaCHg86p2suVdW2prpEZ2gUjzlV3yksAvc0wB9V93S', 'KEME ABADI', 32, 'sponsors/32.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:21:47', '2015-03-24 10:21:47'),
(101, 'PAR0034', '$2a$10$7HqcYtG.tY317JRbSzHPCOI7IiGM.3hjmNahs6H9FlioaHjWT/tWC', 'EBIKABOERE AMARA', 34, 'sponsors/34.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:25:10', '2015-03-24 10:25:10'),
(102, 'PAR0035', '$2a$10$nvgXEOgxJkdBsHPwCahKMOCPq1SMQi8ngqOx0j63Qm2LeVbZGmHp6', 'CHIAMAKA ANIWETA-NEZIANYA', 35, 'sponsors/35.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:26:48', '2015-03-24 10:26:48'),
(103, 'PAR0036', '$2a$10$ii7pvhtQ7Fb9tbhog38EP.nWMjD/AuxUcLvOVl7mmnLIO6mb/wDs.', 'KENDRAH BAGOU', 36, 'sponsors/36.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:28:15', '2015-03-24 10:28:15'),
(104, 'PAR0037', '$2a$10$C3jcVHqYNAlvihXuHaz0Cuc/5UOVwVTCTmOLvExkjefUf8S0sdzhq', 'OKEOGHENE ERIVWODE', 37, 'sponsors/37.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:29:35', '2015-03-24 10:29:35'),
(105, 'PAR0038', '$2a$10$R/zjgrO5dGkQhCcHlELbw.y6HZTNX0hwpymynCqzd7KBwxfd78le6', 'AYEBANENGIYEFA GEORGEWILL', 38, 'sponsors/38.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:30:56', '2015-03-24 10:30:56'),
(106, 'PAR0039', '$2a$10$UTArCrnkCqIsoIXqAybWYetG7.1wszSs6zw4oWt8IiRXYo/l4Tk8.', 'ROSEMARY ITSEUWA', 39, 'sponsors/39.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:32:20', '2015-03-24 10:32:20'),
(107, 'PAR0040', '$2a$10$peB4hVYgovLAJOVnV39Wg.40zVrrmHE0gfyOia34JAzVsBPjm0N2K', 'VICTORIA JOB', 40, 'sponsors/40.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:33:22', '2015-03-24 10:33:23'),
(108, 'PAR0041', '$2a$10$2HL35v.3Djpm2JgJ4fwIPejk.A6D4tGOSK7FFoPhIRlzndMXRO/LO', 'HAPPINESS KALAYOLO', 41, 'sponsors/41.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:34:25', '2015-03-24 10:34:25'),
(109, 'PAR0042', '$2a$10$0IwnUjzUa5oQVxqtjSlNrOHJRV6.hzoolP0pWdyzbgC4Z3F8C8oL6', 'ONISOKIE MAZI', 42, 'sponsors/42.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:36:03', '2015-03-24 10:36:03'),
(110, 'PAR0043', '$2a$10$fRVFFpziorjLeJA./7XIDu/JD9h34UKrEOatT4Kvfu2zl9w5HoPhW', 'EVELYN NATHANIEL', 43, 'sponsors/43.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:37:04', '2015-03-24 10:37:04'),
(111, 'PAR0044', '$2a$10$nsOpDhgIC6BK/GZtbKNSf.JnS5z1556eiQfM.pVc1I9n0nP3kD7Ne', 'OYINKANSOLA OBUBE', 44, 'sponsors/44.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:37:58', '2015-03-24 10:37:58'),
(112, 'PAR0045', '$2a$10$6h25TFlnqTtqc2WCQmpzeO5a7Q8FNrAgs3OtGRafiMgYzSBz.6NlO', 'OYINDAMOLA OKE', 45, 'sponsors/45.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:38:54', '2015-03-24 10:38:54'),
(113, 'PAR0046', '$2a$10$/7BQVyd7.h4vzh7x28Sm5OTyl.IMEX4UumRUK7j6GaaunBDumMn8u', 'JIMOH OTORI', 46, 'sponsors/46.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 11:39:32', '2015-03-24 10:39:32'),
(114, 'PAR0047', '$2a$10$ZU1CVjXLVRClVXC7dVyoEO1mUpB9CZ38l5zEo3Gpo5zV1uXyzMvCW', 'CHISOM OKOYE', 47, 'sponsors/47.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:39:55', '2015-03-24 10:39:55'),
(115, 'PAR0048', '$2a$10$FTeUVVDKIVUSgNlbRz3FGe7fVKlFXlAZUzGBE8aPQlaxX4a6AEW6y', 'FUNKE SALAU', 48, 'sponsors/48.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 11:41:13', '2015-03-24 10:41:14'),
(116, 'PAR0049', '$2a$10$cEOLdf7zUKCJpF9AE.G6AOu9WfZAuLjfAIm.rn/KQ0nk9.eUUcjuC', 'IBEINMO TELIMOYE', 49, 'sponsors/49.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:41:32', '2015-03-24 10:41:32'),
(117, 'PAR0050', '$2a$10$h4E/s/F5FKb2FoJlI8dIm.1lueAuGO9a.xElz8OWL2Dr7Z1vykFEG', 'MORUF ADEALU', 50, 'sponsors/50.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 11:42:50', '2015-03-24 10:42:50'),
(118, 'PAR0051', '$2a$10$Ew14Q8oWiWvKs0GmYmzNeOAkd7joAodRjIHykD3qwyHXPD7lNCxSG', 'ENDURANCE WAIBITE', 51, 'sponsors/51.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:44:42', '2015-03-24 10:44:43'),
(119, 'PAR0052', '$2a$10$qEUuBilRIwpIfTqKeYN0C..BYhc8tn4IO3AREVzQ8ZOLyc9mYClti', 'OLUWAGBENGA OJO', 52, 'sponsors/52.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 11:45:33', '2015-03-24 10:45:33'),
(120, 'PAR0053', '$2a$10$eJDpIRuEuFZTPeAwM7cUP.Oe9RPhP6HXJn.o3v3/6sQ0cdWxVq2P2', 'IBUKUN WILLIAMS', 53, 'sponsors/53.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:45:38', '2015-03-24 10:45:38'),
(121, 'PAR0054', '$2a$10$7KaLmNX8NFXZkcOWunnN0ecAytqbk.crKOfzcz5PW5jR5ou.itbNW', 'ADEKUNLE OLOYEDE', 54, 'sponsors/54.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 11:46:23', '2015-03-24 10:46:23'),
(122, 'PAR0055', '$2a$10$oV/AVv3EqA6IMpld45Arp.y1vpR0fN7kWPbf2B3Ixhn/UeOErG3ES', 'OYINLADE ABIOYE', 55, 'sponsors/55.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 11:47:30', '2015-03-24 10:47:30'),
(123, 'PAR0056', '$2a$10$DTxpbssOuoa8SoCpp7x9uOMMKkMmljbDrtEMa7z9EuRjMZ5v/stgq', 'JELILI ODESOLA', 56, 'sponsors/56.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 11:48:22', '2015-03-24 10:48:22'),
(124, 'PAR0057', '$2a$10$EM7.knWxlWaQNk3E7f9C2uAbW2/VAv0wJHiqO9NJt60oOR9ox8F4G', 'OLADAPO ADEOSUN', 57, 'sponsors/57.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:17:24', '2015-03-24 11:17:24'),
(125, 'PAR0058', '$2a$10$/hB3cJl9sHstEBcq3g8qfO4zMsNGA5T34caO0p2n3zlbSrS.91ef2', 'MUBARAK DADA', 58, 'sponsors/58.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:18:11', '2015-03-24 11:18:11'),
(126, 'PAR0059', '$2a$10$Ja827GWpJejlQolAb5HR3O7J5VsritCK29yCJe8XaRBTYIMYySdb2', 'MICHEAL ADEDOTUN', 59, 'sponsors/59.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:19:09', '2015-03-24 11:19:10'),
(127, 'PAR0060', '$2a$10$sCmeKHC4x0viaeDLBosdj.2RdIQ/gAFa.I/T1ri6DZjXw9v7wy4Ze', 'DEBORAH AGUNBIADE', 60, 'sponsors/60.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:21:48', '2015-03-24 11:21:48'),
(128, 'PAR0061', '$2a$10$nTAO.OfWBVTd9hmRUmy7ze1yvn/RUQwJ4P.ZuaxPjQjGm2.T3DTTa', 'ADEKUNLE HAMZAT', 61, 'sponsors/61.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:22:32', '2015-03-24 11:22:33'),
(129, 'PAR0062', '$2a$10$FaM9baGYD3mL.IXsF.091O/lBSSc03TQH7kgAc9ozKnpno7KM8BE6', 'EMMANUEL LALA', 62, 'sponsors/62.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:23:09', '2015-03-24 11:23:10'),
(130, 'PAR0063', '$2a$10$ZiHebrEINMUinsGCVdJXlO85R2EvWpiZm96CRQ66P4cpak6d5AC06', 'ADESOJI OKESINA', 63, 'sponsors/63.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:23:48', '2015-03-24 11:23:48'),
(131, 'PAR0064', '$2a$10$2P6s7y7y2Tqgmdf1GD2Xl.5oYwMJIiGf0ZhNzKHfLGmbHxKbtGevO', 'JOSEPH OJO', 64, 'sponsors/64.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:24:30', '2015-03-24 11:24:30'),
(132, 'PAR0065', '$2a$10$dZqLZYwOmtbAnPlEQnKoFeBTVL1m70lNytT1VOePpCVEusRAyyzym', 'IBAZEBO ADENIYI', 65, 'sponsors/65.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:40:25', '2015-03-24 11:40:25'),
(133, 'PAR0066', '$2a$10$IRtfqxhFygmNmHwqyjWiaupjf2V2MXVuDFspWtavAbu3rnfyoacpC', 'OLUFEMI AZEEZ', 66, 'sponsors/66.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:49:56', '2015-03-24 11:49:57'),
(134, 'PAR0067', '$2a$10$nEQfT1ivMEyQ1gXd2SKvde0bo.oqwrPnFR6VZxbPfMZy14dlZo9Ze', 'TAJUDEEN BELLO', 67, 'sponsors/67.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:50:43', '2015-03-24 11:50:43'),
(135, 'PAR0068', '$2a$10$1BR8NszfIVfpxR19QL40Ke.cXrT2o3L0hyx3YDEXHHu016t3I7V1a', 'ADEREMI BELLO', 68, 'sponsors/68.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:51:49', '2015-03-24 11:51:49'),
(136, 'PAR0069', '$2a$10$L4gpglC8obH3bPW6YjA2dOy0LMJgsrNUWn07LEd.emtIVHkUZZzDW', 'KELVIN BRIBENA', 69, 'sponsors/69.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:52:39', '2015-03-24 11:52:39'),
(137, 'PAR0070', '$2a$10$77sa3YzOGL/sIk0YufC1/.QKZIl6yLyk2K7gupA/zPmRuePeyyaua', 'ISAAC FOLORUNSO', 70, 'sponsors/70.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:55:00', '2015-03-24 11:55:00'),
(138, 'PAR0071', '$2a$10$xB0NTUN55OsdLQAVCYhuwujx.vraJ.7pyNmxiegMTL98qNTjT6cY6', 'AMOS OGUNDELE', 71, 'sponsors/71.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:55:31', '2015-03-24 11:55:31'),
(139, 'PAR0072', '$2a$10$Ya4zZs5yzhUZ8EhPj8n7G.eSEgmtJCuRr/oKXDrdsOJAhc22EeAzS', 'OYEKANMI OLAOYE', 72, 'sponsors/72.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:56:12', '2015-03-24 11:56:12'),
(140, 'PAR0073', '$2a$10$5a/W5Kc7uRSa8P3qYA6sOOOjuSfSHPwg/9q6jf6uUDH9jqZH/OfaS', 'EDWIN ONYEBUCHI', 73, 'sponsors/73.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:57:04', '2015-03-24 11:57:04'),
(141, 'PAR0074', '$2a$10$rUMBw1IuL4mlq.FgWU8ZRuMbH6jg9Keq14Phgi2pM2GIpEQ.D6psS', 'ADAOBI EZE', 74, 'sponsors/74.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 01:00:05', '2015-03-24 12:00:05'),
(142, 'PAR0075', '$2a$10$CxDGazSLClycz8OEZ7Z2yOeg8cULVAtI3XVTKuhGC4j0LNWf6daWW', 'HUMPHREY IBETEI', 75, 'sponsors/75.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:24:31', '2015-03-24 12:24:31'),
(143, 'PAR0076', '$2a$10$82a3sbprJBvvlSk4NMMf3eOy/w2XII8dHkIOaa71atkJfqXhBaN8e', 'REGINALD DEDE', 76, 'sponsors/76.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:25:40', '2015-03-24 12:25:40'),
(144, 'PAR0077', '$2a$10$51loLv61H1j/UFDlrVI9D.O825sSFxI/6eNkBCZ4B.VqSratQ5FjW', 'FATIOU ABDOU', 77, 'sponsors/77.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:28:24', '2015-03-24 12:28:24'),
(145, 'PAR0078', '$2a$10$x5HWC95eFTqKIvJ6QU.HxeJ6eUjVLYaEfTugZLBP2ckCVi4HP7U9G', 'OSORU OBIREKE', 78, 'sponsors/78.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:29:12', '2015-03-24 12:29:12'),
(146, 'PAR0079', '$2a$10$lQj.64hq6CVUCIqlnW/3XefP643wKzQiW/Q09qXMU5rDxLV8vYN42', 'SOLOMON UMORU', 79, 'sponsors/79.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:30:09', '2015-03-24 12:30:09'),
(147, 'PAR0080', '$2a$10$VM.QdDc2YdWHwZEb2lI/uO0GafXRQciP38FHx7oOJEZhdxxikPbkq', 'SMDOTH NANAKEDE', 80, 'sponsors/80.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:32:02', '2015-03-24 12:32:03'),
(148, 'PAR0081', '$2a$10$uaQOiGy6rmhQhPwuEYJQZ.nQzM.OtRcFxw.UgkF1yStxb.7GkV7Fq', 'BOB PURAGHA', 81, 'sponsors/81.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:33:19', '2015-03-24 12:33:19'),
(149, 'PAR0082', '$2a$10$D6JDBdfuSIUS/L4Nk5jzfO7JoU7irvzisfOAGNgcbvFa1mZKHEjOm', 'ANTHONY SOROH', 82, 'sponsors/82.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:34:07', '2015-03-24 12:34:07'),
(150, 'PAR0083', '$2a$10$l9eiJKyjBsYPiO.MSM84MeCVp9S2xhVnoFnWOhjoZacKWSDvKZBzy', 'CHRISTOPHER MADDOCKS', 83, 'sponsors/83.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:34:59', '2015-03-24 12:34:59'),
(151, 'PAR0084', '$2a$10$nFwsUwDeewpgGW4DtmeCOe2Y2Kf7nzlvLTCm6j44WcXzIJtYzpM1W', 'OSAHON ISIBOR', 84, 'sponsors/84.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:35:43', '2015-03-24 12:35:43'),
(152, 'PAR0085', '$2a$10$xBjUrS/nSslelo12HCsSz.Jb384IJ6563X3Vl7utfkJ3Zn0Sk.k2m', 'JOSHUA ZOLO', 85, 'sponsors/85.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:37:22', '2015-03-24 12:37:22'),
(153, 'PAR0086', '$2a$10$X4l0CqV9pHWBe3UAwnDVEObPPns1e8mzebSGkc6VUmdO7gizoBcQa', 'EBIKABO KOROYE', 86, 'sponsors/86.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:38:31', '2015-03-24 12:38:32'),
(154, 'PAR0087', '$2a$10$gXnY6k8ZOTeUz6y8fuYoMOh.9Jk5pt2zWnFEvjSiYB4ZwA6o/xjYO', 'MONEYMAN AMAKEDI', 87, 'sponsors/87.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:39:27', '2015-03-24 12:39:28'),
(155, 'PAR0088', '$2a$10$dgY8H031INFUy/c3T5VthOYR1GZN0mFpN3IhmnIkXp85JRAB13pGG', 'SUNDAY AZUGHA', 88, 'sponsors/88.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:40:04', '2015-03-24 12:40:04'),
(156, 'PAR0089', '$2a$10$hQ9UlVUM3.m6Zo/6H804ROtNdJc6hlqbEryzWlYHc.NZQwLUwiOEG', 'SAADU ABDULLAHI', 89, 'sponsors/89.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:40:06', '2015-03-24 12:40:06'),
(157, 'PAR0090', '$2a$10$JUdIcBx4VGzd0d7B9MIqFeREIFVfnNk/Lg62SKet6jLmjyOUlLW.G', 'ABDUL INENEMO-USMAN', 90, 'sponsors/90.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:41:00', '2015-03-24 12:41:00'),
(158, 'PAR0091', '$2a$10$zrWFqdEyiTIDs7RO2JeNUeQnKGuox0SP7/vzo1Ox4cRdbp5b3Wcg.', 'J.A ADEYEMI', 91, 'sponsors/91.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:41:01', '2015-03-24 12:41:02'),
(159, 'PAR0092', '$2a$10$hGVSMbSGBcP2i77pyJNoNumrqy6pHkl2DBADn.4xprb6X2MYskuUe', 'ABDUL ADEWOLE', 92, 'sponsors/92.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:41:40', '2015-03-24 12:41:41'),
(161, 'PAR0094', '$2a$10$Zg3BOUPT0vG8S.ZvUsD5vOXsN4ZMqSAaAuPZUFr1RNUhxFa3IMo.2', 'OLAKUNLE KUSHIMO', 94, 'sponsors/94.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 01:43:36', '2015-03-24 12:43:36'),
(162, 'PAR0095', '$2a$10$OzUInkSG87CeFSAOL.MKsOz5EpauZEsBv2UzGhhFjp8823n78uR8C', 'AZIBABHOM SAM-MICHEAL', 95, 'sponsors/95.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:43:46', '2015-03-24 12:43:47'),
(163, 'PAR0096', '$2a$10$fvSj0EbblC/mH765moeFLuHjjG3BxLcVE3waVCucMIgeDkGQmJ9A2', 'ADESOJI AJIBODE', 96, 'sponsors/96.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:44:21', '2015-03-24 12:44:21'),
(164, 'PAR0097', '$2a$10$qz0lYSqmQunVXvZg61OkLe/U9rwO9/AAQo9FFXQc4XijJDCh/NECS', 'AYIBATARE BAGOU', 97, 'sponsors/97.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:44:58', '2015-03-24 12:44:58'),
(165, 'PAR0098', '$2a$10$w9HSU.xITlExLo8O4qEh7u0B1iWfSA.iMCk3gAxgJnJPChyiAWOdK', 'OMOLADE FALOYE', 98, 'sponsors/98.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:45:33', '2015-03-24 12:45:33'),
(167, 'PAR0100', '$2a$10$dFl1jG8ISkochVQaaSbyF.9PyrdBGc2aF88owalns6qU9S.5kwuGG', 'NIKE ISIKPI', 100, 'sponsors/100.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:47:14', '2015-03-24 12:47:14'),
(168, 'PAR0101', '$2a$10$pq5lgs/4X6XkWZzm7wEjTO8T3GsunclBYI95xp1sgVDxVMOGUsPcm', 'LINA ORHIUNU', 101, 'sponsors/101.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:47:23', '2015-03-24 12:47:23'),
(169, 'PAR0102', '$2a$10$zyRYDcjf1bdkZIvAwdjNcu/ycZMvzAflGqbxQMChYct7r/2ISchQW', 'O.O IMASUEN', 102, 'sponsors/102.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:48:37', '2015-03-24 12:48:37'),
(170, 'PAR0103', '$2a$10$FSXfxBZ4FH0kdcqSfy22geJ9C8C00ZyhzhqhSf/L6mnfCHGBgQhSi', 'MUHSIN MOMOH', 103, 'sponsors/103.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-24 01:49:33', '2015-03-24 12:49:33'),
(171, 'PAR0104', '$2a$10$o0NLb4Xdyt3KRmiL/.1HUuhjv2v4ZH9rVRLXHfgxqtvtQLhg.l4z.', 'YUSUF ISHOLA', 104, 'sponsors/104.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:49:53', '2015-03-24 12:49:53'),
(172, 'PAR0105', '$2a$10$eDA.pZfY7/l04FFSs0p2jukeA5RLoG8h2il3r4XhbCZTMhSh2r/3m', 'NORBERT MBAEGBU', 105, 'sponsors/105.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 01:51:28', '2015-03-24 12:51:28'),
(173, 'PAR0106', '$2a$10$hXkcLzng8o8BmQBIXyclCeBfI0OFOVTYNgDl86mVjMTJ2IGpyvB0W', 'JOSEPH MADUEKE', 106, 'sponsors/106.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:51:34', '2015-03-24 12:51:34'),
(174, 'PAR0107', '$2a$10$pZCd/TlAD9IMDm/BQQmVwOj/kmVYVJE65eh5H0Vq41BzQib3fs2UO', 'AYODELE ODUFUWA', 107, 'sponsors/107.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:54:29', '2015-03-24 12:54:30'),
(175, 'PAR0108', '$2a$10$weUPZchU9.PBbpmvOzONLuRUDCkw8AAe.dHhvh23mjgpX54.g45N2', 'P.A', 108, 'sponsors/108.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:56:51', '2015-03-24 12:56:52'),
(176, 'PAR0109', '$2a$10$cgP4OW6gblQYQ25qoV6w8.Xdi/e090w1/G1ev5lBZ.CwzBqEGlv32', 'MATTHEW OLORY', 109, 'sponsors/109.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 02:00:01', '2015-03-24 13:00:01'),
(177, 'PAR0110', '$2a$10$EjeEG936xQLnDuNkbxUZDOye/vUP5SmZqyi4C5Nph/VDgQPznBPcW', 'EMMANUEL TOBIAH', 110, 'sponsors/110.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-24 02:00:32', '2015-03-24 13:00:32'),
(178, 'PAR0111', '$2a$10$pl5Iucj6/o98PaRx/2Lyl.oDm8gtvWPn5XLVz5sZpkLZl80jeN5cu', 'MATTHEW OLORY', 111, 'sponsors/111.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 02:01:04', '2015-03-24 13:01:04'),
(179, 'PAR0112', '$2a$10$FNpVNSB.8hfqVUsCbvGOJOvR3XLX6qsN8uUg16F124lfBPpazjCVC', 'MATTHEW ONEH', 112, 'sponsors/112.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 02:06:06', '2015-03-24 13:06:06'),
(180, 'PAR0113', '$2a$10$JNEdJWv1S3e3YodaS5dGJu3F7UB0OjIZ7Ywomy25KyTGNU5fGYy6i', 'ISIAKA OKE', 113, 'sponsors/113.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 02:11:48', '2015-03-24 13:11:48'),
(181, 'PAR0114', '$2a$10$K4pxzExQyKOVNr0L/p8.8O3H/qA.TYs2eQheQXdYRuCUsh3nP5ipe', 'NKEREUWEM ONUNG', 114, 'sponsors/114.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 02:12:04', '2015-03-24 13:12:04'),
(182, 'PAR0115', '$2a$10$S4197J/8y2fq.BtJkiQGL.iEU4lCPQibaJAEfhS.3TteMyibLn/Y6', 'KINGSLEY OSADOLOR', 115, 'sponsors/115.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 02:15:02', '2015-03-24 13:15:02'),
(183, 'PAR0116', '$2a$10$EjdSMs/zg1kA/c26Arf6KeQ93fPm7TNbVUP0FsC4C7XVLO9/3TmUC', 'FAITH ATABULE', 116, 'sponsors/116.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:18:25', '2015-03-24 13:18:26'),
(184, 'PAR0117', '$2a$10$GTPIhm4VZXKWtOkfZEqKcOMEVUel0h0Pfj6N/vwkBbGdsWbIkxZAi', 'OLAMIDE KUSHIMOH', 117, 'sponsors/117.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:19:05', '2015-03-24 13:19:05'),
(186, 'PAR0119', '$2a$10$D6.ojGOtHHamVIBVWC7c4urakks8EdeMk/R3M8b9HKnBDAB3qajSC', 'MOTUNRAYO OGUNDIMU', 119, 'sponsors/119.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:21:29', '2015-03-24 13:21:29'),
(187, 'PAR0120', '$2a$10$BmY0LIYpq3VlILtRKNFyTeUXbbSLvPCQDjBkVMzmdJvIGRzwMph6W', 'HAUWA BUHARI-ABDULLAHI', 120, 'sponsors/120.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:22:41', '2015-03-24 13:22:41'),
(188, 'PAR0121', '$2a$10$BGNCzKaavb019DbO7HjioewXo7GPq8FOIwKPy/SM5cMooLCyqz5qy', 'AYOMIDE FALOYE', 121, 'sponsors/121.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-24 02:22:59', '2015-03-24 13:22:59'),
(189, 'PAR0122', '$2a$10$qnHYpA09lyevUx9CRM.ccu1sYjBQRaaJXKc1MKIIyiJ/VD0UEZEE2', 'ENIOLA LAWAL', 122, 'sponsors/122.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:24:32', '2015-03-24 13:24:32'),
(190, 'PAR0123', '$2a$10$tvpp/xerb743VO8nWdvUCu1npZ8lyVzpk51mm4/kbP8mo74IyCndW', 'TOMISIN ASUBIARO', 123, 'sponsors/123.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 02:24:51', '2015-03-24 13:24:51'),
(191, 'PAR0124', '$2a$10$o2WjHjv075Nn8zwIt7t0TeXkqSGksPBlB3Y8V9o/H3MXB/xsW9vMe', 'OKEY IBEKE', 124, 'sponsors/124.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 02:25:03', '2015-03-24 13:25:03'),
(192, 'PAR0125', '$2a$10$yzdFj3K/HSqV06rZR7dld.qDErfcze.6YqTF6oFarLTVwXnZuE5BO', 'EMILY ITSEUWA', 125, 'sponsors/125.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:26:10', '2015-03-24 13:26:10'),
(193, 'PAR0126', '$2a$10$p7cTR.Thx/DR5s9C1eumJO5g5j/8w2n9OLEsz2jH7Pb4VXhN4afu2', 'OLUWAFUNMILAYO OSHOBU', 126, 'sponsors/126.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:27:47', '2015-03-24 13:27:47'),
(194, 'PAR0127', '$2a$10$EIPvex.v34lChOSJ6Iid1ush0rj3uyCPgqE177SJeqW/57R4MBheW', 'OLUWASEUN SANNI', 127, 'sponsors/127.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:28:52', '2015-03-24 13:28:53'),
(195, 'PAR0128', '$2a$10$zyZS.rpeX.pQGGiBkUJ0n.Q.I9YfL3gkGb0Uc/0u3vEdYYpxGFqhC', 'JENNIFER ONYEMAECHI', 128, 'sponsors/128.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:29:56', '2015-03-24 13:29:56'),
(196, 'PAR0129', '$2a$10$ppdMTmPAXgcjHKmDCeHaueCb/o8rkLpjYZcKUvZiCUi8tQpSgBnvK', 'RUKEVWE ERIVWODE', 129, 'sponsors/129.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:31:00', '2015-03-24 13:31:01'),
(197, 'PAR0130', '$2a$10$8o/M6lMtiTFL30HaVYy9KOJeAdZZ3716JeWyU1YPtYL7wBpJyhznC', 'HABEEBAT LAWAL', 130, 'sponsors/130.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:32:03', '2015-03-24 13:32:03'),
(198, 'PAR0131', '$2a$10$xjdasZKqjWsABzuz5t5Q6uG2jWXI17kLFFFjSw398Ij31m92xCy6u', 'IBUKUN POPOOLA', 131, 'sponsors/131.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:32:59', '2015-03-24 13:32:59'),
(199, 'PAR0132', '$2a$10$j/VKZUHJWCzaKhyOwFQPxe.8MwuaaCRcxQopl1YVwcB9kticAqf0O', 'OLUWATOMIWA NOIKI', 132, 'sponsors/132.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:33:52', '2015-03-24 13:33:53'),
(200, 'PAR0133', '$2a$10$oWR1k26aLR7u2CxE24UyWOYwny6EDG9R634I.diW.YYYZX.P.Drs.', 'SOMKENE EZEJELUE', 133, 'sponsors/133.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:34:55', '2015-03-24 13:34:55'),
(201, 'PAR0134', '$2a$10$YPAxloswhPJ3V1qTC/44L.oz7mSyL42V1iCr7jHBkPUGfKID.7Z/u', 'KAYODE FALUADE', 134, 'sponsors/134.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 02:48:18', '2015-03-24 13:48:18'),
(202, 'PAR0135', '$2a$10$Q7m0zf8r4rRShAA7r.zYtuXvW3VyiyMNIwRMT9FVPvioPziO2uKNy', 'OGHENEYOMA HAMMAN-OBEL', 135, 'sponsors/135.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-24 02:48:23', '2015-03-24 13:48:24'),
(203, 'PAR0136', '$2a$10$HQ8W7TW4IOGvWJ8ZC50o7.qMmoaT/vbQItmiv1Qv40Xvd/saBT/X6', 'IBRAHIM AKINTOLA', 136, 'sponsors/136.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 02:50:38', '2015-03-24 13:50:38'),
(204, 'PAR0137', '$2a$10$E6upQkf7XSv8ma0q7O5vcey/5odeomILYkKofV0KT8SGf5I3LhfDG', 'ADETUNJI HASSAN', 137, 'sponsors/137.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 02:52:09', '2015-03-24 13:52:09'),
(205, 'PAR0138', '$2a$10$7Kq2ZvIH.MZxZzTQ8IDE7OL4FrD.XMVS2.PySOGPdwoxcseWodexq', 'VICTOR OKESINA', 138, 'sponsors/138.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 02:53:42', '2015-03-24 13:53:42'),
(206, 'PAR0139', '$2a$10$1AxewdlI3odh6RnYwTFOuOAopx1jAmIv.3BsBLOKIHxL89kYPTc4u', 'ADEYINKA ADENIYI', 139, 'sponsors/139.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 02:54:59', '2015-03-24 13:55:00'),
(208, 'PAR0141', '$2a$10$5fbmq1whWDWC0Fou0CAbbO1T05xVpQSR.JTffs0gbP5uKwCl/gY.e', 'ADEKUNLE ADESINA', 141, 'sponsors/141.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 02:59:11', '2015-03-24 13:59:11'),
(209, 'PAR0142', '$2a$10$60ENXEK7lcVrW1tH6hhGzO9026cv8swqKvCCxAmqO7bj1o9ZIhpKa', 'OLUKAYODE AGUNBIADE', 142, 'sponsors/142.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 03:03:38', '2015-03-24 14:03:38'),
(210, 'PAR0143', '$2a$10$GtC0jpByu0RRO4YY2xsujOryo9JQZnyWPxReYxerRDJqZlJ1CexW2', 'HOPE CHINDA', 143, 'sponsors/143.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 03:04:50', '2015-03-24 14:04:50'),
(211, 'PAR0144', '$2a$10$hm0HvdFgzuXwKt.HIrqdzOnsKh7potbM5c9v.WVgC3hJj3ukZnK2K', 'OLUFEMI SAMSON', 144, 'sponsors/144.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 03:06:43', '2015-03-24 14:06:43'),
(212, 'PAR0145', '$2a$10$mvfjQxP7P0y7opadT.9kIOJJEHTFRXszX9Gv3nTm4.azgdTAPAZTS', 'AMOUDATH ABDOU', 145, 'sponsors/145.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 03:08:15', '2015-03-24 14:08:15'),
(213, 'PAR0146', '$2a$10$EzULmYjBj8sz..cvefhpc.LAG0mrmSPr/jtRnb2QnBNs6kVpx3cSe', 'OLUWATOBI BAKRE', 146, 'sponsors/146.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:13:57', '2015-03-24 14:13:57'),
(214, 'PAR0147', '$2a$10$HdWzvGhFHT87HWZmB5SVre3BNaVFlf/0o3TtCyDL1Q6q6b5jZQ/Ae', 'WILLIAMS CHIEJILE', 147, 'sponsors/147.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:14:55', '2015-03-24 14:14:55'),
(215, 'PAR0148', '$2a$10$KVBBQ3c1GZy7Yt5Py5khTulI2FZN0QIi3hXlXqmpCX/30c.UTz2U6', 'SUNKANMI LAWAL', 148, 'sponsors/148.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:15:30', '2015-03-24 14:15:30'),
(216, 'PAR0149', '$2a$10$aYeBYMDr6W9YNLtPb8MKVuJYvvQcQzUxRfpTUmau37trp3awKZ3ki', 'VICTOR NWOGU', 149, 'sponsors/149.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:16:18', '2015-03-24 14:16:19'),
(217, 'PAR0150', '$2a$10$H8c/VQykuxiTmJM8i1SaVOUKStVPTD9cBSfQckBnoYrBX/eH16qDu', 'CHIGOZIE OKEKE', 150, 'sponsors/150.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:16:56', '2015-03-24 14:16:56'),
(218, 'PAR0151', '$2a$10$rq/T.BQFzUcSivRV7YvsLuY0szpb6bk0WNW74YtQYQ4CCv2x/xoxO', 'TIMILEHIN OGUNBANJO', 151, 'sponsors/151.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:17:35', '2015-03-24 14:17:36'),
(219, 'PAR0152', '$2a$10$nbTy4yRwqkAgeMSqFtYX/OKt91NIK87HMpbLHQEjQlOq1ZdmQd8pK', 'CHRISTIAN ONWUCHELU', 152, 'sponsors/152.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:18:41', '2015-03-24 14:18:42'),
(220, 'PAR0153', '$2a$10$n/bwFMlCFpNkfn2lk8SPruAwxXzbOaTIpQYCFBUgs4xvT5SK4zP7G', 'OLUWASEUN SOYEBI', 153, 'sponsors/153.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:19:19', '2015-03-24 14:19:20'),
(221, 'PAR0154', '$2a$10$Sk.g/RlWVMG5FsYRsSawd.8COYO..MX2pAHNBNgUIVACzD0x7947O', 'CHIBUEZE UDUJI-EMENIKE', 154, 'sponsors/154.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:20:06', '2015-03-24 14:20:06'),
(222, 'PAR0155', '$2a$10$Mdt4oBahOR0GJq4wMswBbuBjj5RQntYIrUjjeFuW7Vkk1FQRL2Vyy', 'OLAOLUWA OLATUNBOSUN', 155, 'sponsors/155.jpg', 1, 'PAR_USERS', 1, 0, '2015-03-24 03:28:01', '2015-03-24 14:28:02'),
(223, 'PAR0156', '$2a$10$Vh.sO5r6PUM/kgHvq7zXWuDmY1krdjPOLYA8U0HcRUa/ZpWDiOTwS', 'FELIX IKPI-IYAM', 156, 'sponsors/156.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:21:53', '2015-03-24 14:21:53'),
(225, 'PAR0158', '$2a$10$yy0EYgDGXEZrkpZjcwnBxODBCUNJY8WrSG.8ntUVU3ScGRZuO9vom', 'OLAWALE KAZEEM', 158, 'sponsors/158.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 03:38:18', '2015-03-24 14:38:19'),
(226, 'PAR0159', '$2a$10$t5TDN7QIGW4BLBwc8h4rq.EttW7Nkg3Lc7wwOG83Ghy5U74uyw6tS', 'CHRISTINA UGOCHUKWU', 159, 'sponsors/159.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 03:44:20', '2015-03-24 14:44:20'),
(227, 'PAR0160', '$2a$10$FwZuZ.GP154/j5HAkPBdweq/1nRkQ/KypiUIVCuvoNv08L3BAqlHa', 'BABAFEMI  OJUDU', 160, 'sponsors/160.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 03:52:35', '2015-03-24 14:52:35'),
(228, 'PAR0161', '$2a$10$HPlCdZ/YwpKSVu9cCOlZ6uBByWL7YNYe.OxslM0YCXYmiarU5rSwu', 'WURAOLA AFOLABI', 161, 'sponsors/161.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 03:55:54', '2015-03-24 14:55:55'),
(229, 'PAR0162', '$2a$10$DAVP69pUBeJtbL/8tOZhCui/SHMYYYfrNOICEm2mEgl.QW1fAvdYe', 'EMMANUEL ANGEL', 162, 'sponsors/162.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 03:56:54', '2015-03-24 14:56:54'),
(230, 'PAR0163', '$2a$10$dopc6euJZvS2wmcRn50l6e1wxBrPhwPjBMlkaPxs9savz39CdzRze', 'IRENE IKPI-IYAM', 163, 'sponsors/163.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 03:58:14', '2015-03-24 14:58:14'),
(231, 'PAR0164', '$2a$10$S9Lpbi5cgxro3L3IssjQRODo6kn1bpVlsELHIym7FsiEsO0nDlPce', 'PRECIOUS JOHNSON', 164, 'sponsors/164.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 03:59:31', '2015-03-24 14:59:31'),
(232, 'PAR0165', '$2a$10$7Qfq7BCIG7vGYFSOncnIrOeDYpmy.OeKXwxNZ2/YiNB7r1/zZxPpK', 'VIOLA OKEY-EZEALAH', 165, 'sponsors/165.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 04:02:07', '2015-03-24 15:02:07'),
(233, 'PAR0166', '$2a$10$ECsApzbVrSwhZ5MdwuTCc.v633FQ1ksYqMVJ1QvEMHykLzjA89x3K', 'YEMISI OSHOBU', 166, 'sponsors/166.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 04:03:30', '2015-03-24 15:03:31'),
(235, 'PAR0168', '$2a$10$Ho42ynPloOKzfaA/Qa2RJ.sEKtDkkfkOO3qiDGfYAWXTKh9F2wztS', 'ANIKE SOBOWALE', 168, 'sponsors/168.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 04:05:42', '2015-03-24 15:05:42'),
(236, 'PAR0169', '$2a$10$W34NS77Sgw2wl89lAkjFNu5Fsw7LJPITUkBWwExskbGLf/BFqlg3a', 'MARIAM YAHAYA', 169, 'sponsors/169.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 04:06:59', '2015-03-24 15:06:59'),
(237, 'PAR0170', '$2a$10$fMg7DtvMRnVX9zGIM0P9kOQN0W8q8sIAKw5kXUpSAyLZTv11sHx9C', 'RAJEEV DANDEKAR', 170, 'sponsors/170.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:09:02', '2015-03-24 15:09:02'),
(238, 'PAR0171', '$2a$10$/ea4uQmREu2X8GVOf5RW1eJFUZ3KCLFlIeXv2UYtfyXoutzlLm4uy', 'KENNEDY ONONAEKE', 171, 'sponsors/171.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:10:28', '2015-03-24 15:10:28'),
(239, 'PAR0172', '$2a$10$H1m6a2Pkuvz3cuCmEerhHOqjshbClsj293SnzRJXXD35uDMlv3/aa', 'PETER PAUL ANAGBE', 172, 'sponsors/172.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:12:03', '2015-03-24 15:12:04'),
(240, 'PAR0173', '$2a$10$etnFTQG38Ikpmr4EcREtAepkbf4uvu7cdGYtkVhKUE/MRHcwWzr3G', 'OLALEKAN ALAYANDE', 173, 'sponsors/173.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:13:06', '2015-03-24 15:13:06'),
(241, 'PAR0174', '$2a$10$64lmlUC5uCqGrgn/gDlKOujGTim8Y.J0yuUV9mlS.pl2qlbdEdTUm', 'MUFTAU OYENIRAN', 174, 'sponsors/174.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:13:52', '2015-03-24 15:13:52'),
(245, 'PAR0178', '$2a$10$/N4DPTXFKnGO5pUHQeaD4.hR7P4pgkpJLPVwSn2lUwNdAyqUS4pqW', 'ADEDIRAN OLUKOKUN', 178, 'sponsors/178.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 04:24:32', '2015-03-24 15:24:32'),
(246, 'PAR0179', '$2a$10$/7MU61LqYGEJ.LCIAw1VpOQ2tQHWCPAsM0O/jcx4SkBrBa4EIL7f.', 'ADEBAYO AKINTELU', 179, 'sponsors/179.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:27:11', '2015-03-24 15:27:11'),
(247, 'PAR0180', '$2a$10$iPp.U55rSExHjpWvzyZ3xuTU8VwiFPdru1EoiQ9G88.yJavA0RYBi', 'ADEPOJU LAWRENCE', 180, 'sponsors/180.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:35:02', '2015-03-24 15:35:02'),
(248, 'PAR0181', '$2a$10$VkZAt.cBwUpFedVHv8bEkeoGIzFX7ylYYL7zf0mV6J3UTQNbVmx/e', 'HAFEEZ ABIOLA', 181, 'sponsors/181.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:35:06', '2015-03-24 15:35:07'),
(249, 'PAR0182', '$2a$10$wi/VdYOnR2dDm/zoh7SVL.vRSXadiJ4r/k1z4MtXa3Gh8Zn4rXlPO', 'ADEOSUN OLADAPO', 182, 'sponsors/182.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:36:06', '2015-03-24 15:36:06'),
(250, 'PAR0183', '$2a$10$6Yvw6VfMG/xrZQp6uylpz.WFaOZLyVsoTzsG5YVeDRR/97G8hhc6G', 'ABDULSALAM  ADENIYI', 183, 'sponsors/183.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:37:02', '2015-03-24 15:37:03'),
(251, 'PAR0184', '$2a$10$qoxLp/shPQoRe9dIbM.dR.m0h4GdFJHP54izb.8bYuuFl3HYzOwmu', 'BELLO UBANDOMA', 184, 'sponsors/184.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:37:47', '2015-03-24 15:37:47'),
(252, 'PAR0185', '$2a$10$mrm/0GtvRTQ5rWwwQTjfv.0kx2ZekC6IeKRT8EoNqPiF4w5phKatC', 'ISLAM AJIBOLA', 185, 'sponsors/185.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:38:16', '2015-03-24 15:38:16'),
(253, 'PAR0186', '$2a$10$MQzPl3k3yittjLztCYGGLOrNrPSWwzmazqiMMZ2fmpWRit0mE9j6C', 'OLUDAYO BAKARE', 186, 'sponsors/186.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:39:18', '2015-03-24 15:39:18'),
(255, 'PAR0188', '$2a$10$Y/tEk4RCELp6spmiiOMzB.zVUzxoST8g8omiFehWgeH0MiQGzpQ0G', 'AYOTUNDE BELLO', 188, 'sponsors/188.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:40:26', '2015-03-24 15:40:26'),
(256, 'PAR0189', '$2a$10$y0V3leiq6Dd9znoaBIAEIuH69nF73WzVGperZCxKULdiQ56hu7nOK', 'OBINNA EMMANUEL', 189, 'sponsors/189.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:41:32', '2015-03-24 15:41:32'),
(257, 'PAR0190', '$2a$10$jUN5/gCyUq.e18kNRYa4EeNc9QC6VyjcVDljTgAgNc1ys8kwH5/GS', 'IYIOLA FOLORUNSO', 190, 'sponsors/190.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:43:05', '2015-03-24 15:43:05'),
(258, 'PAR0191', '$2a$10$lGJtwo2LAe13yPoIZLBpuO5OWkrOY.wMo0g.TsdEzaCnvIWbyRv0.', 'OLUWABUKUNMI IDOWU', 191, 'sponsors/191.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:44:17', '2015-03-24 15:44:17'),
(259, 'PAR0192', '$2a$10$UC7FOBVHZMYLOMdb7cPXaukd8Xd4hTu5EpcH0LaskRqFaXaYUAUu2', 'OMAGBITSE NIKORO', 192, 'sponsors/192.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:45:18', '2015-03-24 15:45:19'),
(260, 'PAR0193', '$2a$10$MiM1lm7m4Nyo6dfDiz3hSOvHUtTQ1PrEWtmD3HVxaimkQe9hFzk7y', 'I FAYOMI', 193, 'sponsors/193.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:45:48', '2015-03-24 15:45:49'),
(261, 'PAR0194', '$2a$10$cFTcRqRAB8gwf3/TkXXJjuz04Fzs5/N0DZNEMZ/btaRC8Q0KDN31q', 'SAMSON OBRIBAI', 194, 'sponsors/194.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:46:23', '2015-03-24 15:46:23'),
(262, 'PAR0195', '$2a$10$BPYyZlXUo5R06osahnXqzeensLyUrDbFufh5nr3GqlJb1PJRYW9XW', 'CHURCHIL ELENDU', 195, 'sponsors/195.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:46:53', '2015-03-24 15:46:53'),
(263, 'PAR0196', '$2a$10$vUyhA0jqfeHCUSNrXtHPVOgE8W35G9m7oysnGBY4/n98UOAOO8wce', 'MOBOLUWADURO OGUNDIMU', 196, 'sponsors/196.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:47:24', '2015-03-24 15:47:24'),
(265, 'PAR0198', '$2a$10$MxhtoRQLI73YXnFILngvnuUQbanp0e5nIAMSK6x5ipnjcwkYBr/tS', 'AYOOLA OGUNEKO', 198, 'sponsors/198.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:48:52', '2015-03-24 15:48:52'),
(266, 'PAR0199', '$2a$10$5ucb0CJKBruIuT5NAxUNr.XREhyfibfgGfniQCiqfQfy0KzXC6bma', 'PAUL OKOYE', 199, 'sponsors/199.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:49:29', '2015-03-24 15:49:29'),
(267, 'PAR0200', '$2a$10$9qHyVM7Id3mQNDYrzt4GRebAruvc0XQdTb.cXkkCnTDLF6m8hnHSm', 'NATHANIEL OKPARA', 200, 'sponsors/200.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:50:29', '2015-03-24 15:50:29'),
(268, 'PAR0201', '$2a$10$1rd.K6ZueEl75TETB0sNKukNts3CAYy7ykg80zzRt7s2vwVF6Kebe', 'AYOTOMI  SOWOLE', 201, 'sponsors/201.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:51:28', '2015-03-24 15:51:28'),
(271, 'PAR0204', '$2a$10$bBtSfF4MjtZkrk4Bf2FkFuWODp4xDzPAVbmI9rqt8B4LHA8zpk/Ry', 'SOGE ABAYOMI', 204, 'sponsors/204.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 06:55:11', '2015-03-24 17:55:11'),
(272, 'PAR0205', '$2a$10$9qQXjf7kGzu2zPSWMGSqyeZlM4w53agQKnhgnKq95wGMR9h43CBOi', 'RAJI HABEEB', 205, 'sponsors/205.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 06:58:45', '2015-03-24 17:58:45'),
(273, 'PAR0206', '$2a$10$zqDB3qaqRb6nJciA2Nu1NOgVYzYWZV/3TbCttaSNPXpeBVjraPDlO', 'OSINAIKE OLANREWAJU', 206, 'sponsors/206.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 07:04:54', '2015-03-24 18:04:54'),
(274, 'PAR0207', '$2a$10$UKGPE5mgS8XjsZclmpj6we9vNEuPGIntCEdxRtntlKltvFxMqTcLW', 'AMZAT YAYA', 207, 'sponsors/207.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 07:08:01', '2015-03-24 18:08:01'),
(275, 'PAR0208', '$2a$10$P3/6.h7eFce76NpNHdywJu3qWVxUHvmUYvTkChdIClcApiYxV9suK', 'SOGE OLUMUYIWA', 208, 'sponsors/208.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:12:08', '2015-03-25 07:12:08'),
(276, 'PAR0209', '$2a$10$Y4eBsQgwVLRpC4VS6bH94O0uG82zCyKs63rr0CBejFCC3s0v44zqO', 'SHADOUH HANI', 209, 'sponsors/209.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:15:40', '2015-03-25 07:15:40'),
(277, 'PAR0210', '$2a$10$1BUY8hEFnsATOjK.fkQYQ.sZivGb.HOQOfcO4cvKradr/o24Ur7q6', 'IBAZEBO ADENIYI', 210, 'sponsors/210.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:17:47', '2015-03-25 07:17:47'),
(278, 'PAR0211', '$2a$10$gYaq/NCiG5lWy13oyD60IOj/iLcUiWDa1X3Z/Wzc/heLD3SROD2xW', 'AJISEBUTU OLUSAYO', 211, 'sponsors/211.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:20:41', '2015-03-25 07:20:41'),
(279, 'PAR0212', '$2a$10$Q.zupOfk0GvYDAd1bT/GV.sHOSuSQC42gbqZzaSN8s8ZEi/2elgpq', 'OSHUNLOLA YISA', 212, 'sponsors/212.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:21:29', '2015-03-25 07:21:29'),
(280, 'PAR0213', '$2a$10$Lfp.vxEHJ2GZCQDMsR/YsuNLsq57NV6GOthOw2S4hDSDsMSNRDMpy', 'OLAORE OLUDARE', 213, 'sponsors/213.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:22:43', '2015-03-25 07:22:43'),
(281, 'PAR0214', '$2a$10$RMecvAnNLq8nvaiEtcOTWeNoCJWZWT.tm42pdoyLXj3xez0snIdGS', 'OLASEDIDUN TUNDE', 214, 'sponsors/214.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:26:32', '2015-03-25 07:26:32'),
(282, 'PAR0215', '$2a$10$hpUguTzlR6KqW6VjO/YRZORiul8ErCVEvbLxdqbsCK5ro5bOSy6ry', 'ADEPOJU LAWRENCE', 215, 'sponsors/215.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:28:22', '2015-03-25 07:28:22'),
(283, 'PAR0216', '$2a$10$6opOVcizmAQMSsWDL7Kxt.s6k1sEgug7eaLZ/vykd7N2tGoVCDksa', 'ONWUCHELU EMEKA', 216, 'sponsors/216.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:13:15', '2015-03-25 08:13:15'),
(284, 'PAR0217', '$2a$10$SSlXW1RrbZD8H8nPW4/UlOFKy7gYpg.EdoRiGojJD052aPoI3ZbaS', 'ISHOLA BOLAJI', 217, 'sponsors/217.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:19:24', '2015-03-25 08:19:24'),
(285, 'PAR0218', '$2a$10$W3hCUxlITQz1YDqPRvZ1JOx.mS/y21iSq.2S.FFYmC0hd8lKIApKm', 'AKPAMA PAUL', 218, 'sponsors/218.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:23:02', '2015-03-25 08:23:02'),
(286, 'PAR0219', '$2a$10$ls7nNLluzYs90ByBz6et6egz6DdvKM8rzf7HruR0qGEuOGnkSnezG', 'WIKIMOR JOHN', 219, 'sponsors/219.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:25:44', '2015-03-25 08:25:44'),
(287, 'PAR0220', '$2a$10$MqDH66YRr9fHp/lrh8yGO.dQKbAcZxfUc.WGy5C/tPRHO.NKacSde', 'ZIWORITIN EBIKABO-OWEI', 220, 'sponsors/220.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:30:26', '2015-03-25 08:30:27'),
(288, 'PAR0221', '$2a$10$x5rxRkLGZFbkwh3QBTdo5.teeoiXZFQqUeZzwU9xtU31Ztd.0LSs.', 'OLUMESE ANTHONY', 221, 'sponsors/221.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:31:19', '2015-03-25 08:31:19'),
(289, 'PAR0222', '$2a$10$1YJTCGibDbdzZbiwyNp2l.EoNHG.Sz/Y.xnNBt7gYWW58dtYUWjza', 'MARKBERE ABRAHAM', 222, 'sponsors/222.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:33:05', '2015-03-25 08:33:05');
INSERT INTO `users` (`user_id`, `username`, `password`, `display_name`, `type_id`, `image_url`, `user_role_id`, `group_alias`, `status_id`, `created_by`, `created_at`, `updated_at`) VALUES
(290, 'PAR0223', '$2a$10$2qMCIIWd54.f6rp.nYkeVeb.2qfqi8NHq42IEz.b6UVYhkakR488C', 'OKUNBOR IFEANYI', 223, 'sponsors/223.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:34:37', '2015-03-25 08:34:37'),
(291, 'PAR0224', '$2a$10$KbkBI8BA9gBKxrl8MYqQ0.G8k9Aq76xNxoI/ygGcVxT0JYbzYELz6', 'OSINBANJO OLUWAFEMI', 224, 'sponsors/224.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:35:20', '2015-03-25 08:35:21'),
(292, 'PAR0225', '$2a$10$N2wi0PDK9VSIXwH/WNg2vu7vIz6.RAQZPa10S4UDlMSXDbrTMl8jq', 'AWOLAJA ADEKUNLE', 225, 'sponsors/225.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:35:58', '2015-03-25 08:35:58'),
(293, 'PAR0226', '$2a$10$CnIMG9ybxYMMFbwvWfESlujdfsb8aKQTvwzO1ID/SFuoOabr9JOyC', 'ABDOU FATOU', 226, 'sponsors/226.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:37:01', '2015-03-25 08:37:01'),
(294, 'PAR0227', '$2a$10$gr9MqojWlIp1ca21oFDD.ueWiUXa4SRggSszXIwwXdJSuza6cnS8m', 'EMMANUEL OFFODILE', 227, 'sponsors/227.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:38:02', '2015-03-25 08:38:02'),
(295, 'PAR0228', '$2a$10$iouU5e9sizud24gDdhvQg.p3W8aATPwP/O3Y92/GbvsNx7dBKoEpK', 'OHADIKE MICHAEL', 228, 'sponsors/228.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:38:40', '2015-03-25 08:38:40'),
(296, 'PAR0229', '$2a$10$9FwzZc6tdg/WzdLzqBBoPOAxCllDJ0nyJ1afymIhgo5XSVagaGHKC', 'OWHONDA OKECHUKWU', 229, 'sponsors/229.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:39:32', '2015-03-25 08:39:32'),
(297, 'PAR0230', '$2a$10$2Bh1Nq/cRNVx8XbZRgGnjObfP5LCi7d5CUcvpxsCMYWOI6t1txdhe', 'ELDINE LAYEFA', 230, 'sponsors/230.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:41:57', '2015-03-25 08:41:57'),
(298, 'PAR0231', '$2a$10$HL2rzezWQve5pKbotpDAZ.NTXJZCvUyclweFG6OXzzSIkvP8dUn0i', 'SIMOLINGS SIMOLINGS', 231, 'sponsors/231.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:45:43', '2015-03-25 08:45:43'),
(299, 'PAR0232', '$2a$10$PvUwOw4KbXjA.Zh8zxqiEOHrRM4SgCB0q30NX/qJRXJTU409mijz2', 'ANAGBE PETER', 232, 'sponsors/232.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 09:51:13', '2015-03-25 08:51:13'),
(300, 'PAR0233', '$2a$10$8DRwj5etmZym3YnYHJ3KleJI3XHlUfkG08HkPDMxvf3.PeZKbJdzK', 'AKINOLA AFOLABI', 233, 'sponsors/233.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 09:51:59', '2015-03-25 08:51:59'),
(301, 'PAR0234', '$2a$10$3jwKFWXQJtpJMyFGCog6ZevfrC5Pl5gWVqOl06BldwVJ7RCAnKboK', 'SHADRACK AMOS', 234, 'sponsors/234.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:53:48', '2015-03-25 08:53:48'),
(302, 'PAR0235', '$2a$10$LGeEj7HK3RSz42yZYHEkbOsTvs7XsZitox0BefuVjB7iEVb.WmZzK', 'GBADEBO ADEBISI', 235, 'sponsors/235.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 09:54:00', '2015-03-25 08:54:00'),
(303, 'PAR0236', '$2a$10$bT0FoDjLONHhxjuxZUHgd.5eTbON./3GCYm0hK0MF7vA0Dgn1vFiy', 'OGUNDEYI NAJEEM', 236, 'sponsors/236.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 09:55:34', '2015-03-25 08:55:35'),
(304, 'PAR0237', '$2a$10$uNC1anL4SttSqcHpZdxbuefMRCjcG4SP9PFpywl6OdsQjz4xcc9H6', 'OGUNBONA ISMAEL', 237, 'sponsors/237.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 09:57:57', '2015-03-25 08:57:58'),
(305, 'PAR0238', '$2a$10$Zb4PM1pjf2SB/tgJhrGRHezXEJaEAqqVd3KUEoLRqiOMboP2MJRsO', 'OLUKOKUN ADENIRAN', 238, 'sponsors/238.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 10:04:05', '2015-03-25 09:04:05'),
(306, 'PAR0239', '$2a$10$S/T9m46SY8c5ROCLULie1eRmNMzVAD5YbQ8KUkMPRq1DqbSJEy3HW', 'OJO OLUWAGBENGA', 239, 'sponsors/239.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 10:04:48', '2015-03-25 09:04:48'),
(307, 'PAR0240', '$2a$10$pbr8nBNMH4fS6ximHMVUnuMsKHUPOuV9m.FwxjFOefq.6uuow9ofC', 'RAJI HABEEB', 240, 'sponsors/240.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 10:05:33', '2015-03-25 09:05:33'),
(308, 'PAR0241', '$2a$10$D6/ZHNmFQUEJPh37ZIhBduiEWLTvP1OULNkD/Gx98i74SwGyy8kR.', 'ADEOLA ROTIMI', 241, 'sponsors/241.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 10:06:21', '2015-03-25 09:06:21'),
(309, 'PAR0242', '$2a$10$yYRs.M8QUfcKURyuowA2/e3bMFxOb1zcVmbeTQbVTEnkSmpSN2UvG', 'OYEDEJI JAMES', 242, 'sponsors/242.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 10:07:28', '2015-03-25 09:07:28'),
(310, 'PAR0243', '$2a$10$n7v2HSrw5T1FEVz0DrOJfOZE6fD1T17FEMAQbIjfDgBTrpRahLphO', 'PROMISE JOEL', 243, 'sponsors/243.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 10:08:33', '2015-03-25 09:08:34'),
(311, 'PAR0244', '$2a$10$skwKN27q1h4KlcUycIREG.ByNl6XSuoucl7nxeJhYxPjkhZ3OZMWC', 'AGADAH EBIYE', 244, 'sponsors/244.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 10:35:52', '2015-03-25 09:35:52'),
(313, 'PAR0246', '$2a$10$W.ucvumVc7s0IQZpXvPaveMJAqTbwKbXDWk5135JdgTvx4IgeCNdu', 'JESUMIENPREDER AYERE', 246, 'sponsors/246.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 10:41:43', '2015-03-25 09:41:44'),
(314, 'PAR0247', '$2a$10$itBTbsNxuwPL9M.AzwfJXeYjTe9qgUVKTMom8/g/sOVvWgpCsGVU6', 'DANIEL EMMANUEL', 247, 'sponsors/247.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 11:35:25', '2015-03-25 10:35:25'),
(315, 'STF0066', '$2a$10$ilsbwTs5VOLIXvzod/RFFOHCiyJpgYQJQ9nVBZTi5zV3.FXLEDAP.', 'ZIWORITIN Ebikabo-Owei', 66, 'employees/66.jpg', 4, 'ICT_USERS', 1, 43, '2015-03-25 11:46:52', '2015-03-26 07:59:53'),
(316, 'PAR0248', '$2a$10$IJNkNhejJlO.ycPqPD29IupJsFllz64uam7vqf99G2Xd8L57W56t.', 'AKUNWA CHIJIOKE', 248, 'sponsors/248.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 12:44:02', '2015-03-25 19:20:25'),
(317, 'PAR0249', '$2a$10$70HBi/QdbC7eNC.L1OUPleJEXNMeTU7dmowPRS9V.fVLMoU4UlQQC', 'ANOKWURU OBIOMA', 249, 'sponsors/249.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 12:46:14', '2015-03-25 11:46:14'),
(319, 'PAR0251', '$2a$10$FjR4zrz/x4vSY/k.1E.TP.TRM5GVoR4DUdzSaOcOuMTfK2i0/H6au', 'BELLO GARBA', 251, 'sponsors/251.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 12:50:12', '2015-03-25 11:50:12'),
(320, 'PAR0252', '$2a$10$KV3cI4yTTOpLMfj1HS8coelJCjwXAWmbvUTzKaPq9fiGE9eChZHma', 'DADINSON-OGBOGBO  DAVID', 252, 'sponsors/252.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 12:51:49', '2015-03-25 11:51:50'),
(321, 'PAR0253', '$2a$10$Umw.MCLgH38AtrEImEL96uwn0mzZ11fhiaFfhZM.EG.P7dDPR3.Ri', 'BAYELSA GUARDIAN', 253, 'sponsors/253.jpg', 1, 'PAR_USERS', 1, 46, '2015-03-25 01:27:30', '2015-03-25 12:27:30'),
(322, 'PAR0254', '$2a$10$eD0v4OP98dz8TrTzBFhjmOTyxaoA6iFsBpdnEKSF9NvoGMLdMz9TC', 'NWOKEKE FAVOUR', 254, 'sponsors/254.jpg', 1, 'PAR_USERS', 1, 46, '2015-03-25 01:31:40', '2015-03-25 12:31:40'),
(324, 'PAR0256', '$2a$10$UQPfQoLX4f5cFT4Q4dZyGeGF3D9FDaOPx5T45AE20JJZSDkSOYW6O', 'DADINSON-OGBOGBO  DAVID', 256, 'sponsors/256.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 02:01:23', '2015-03-25 13:01:23'),
(325, 'PAR0257', '$2a$10$tkUvTFM5ZWM3fFwh5htzI.VMv.3JqGeXifI9y84hCBJ8QuAa0OxHe', 'DAPPAH  OWABOMATE', 257, 'sponsors/257.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 02:05:07', '2015-03-25 13:05:07'),
(326, 'PAR0258', '$2a$10$sAoYs3Ng3860cGAWJmBOXO.TN93zno51mhdG5atNNGQ2uJ14rIKwa', 'EZIMOHA  EBUBECHI', 258, 'sponsors/258.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 02:09:37', '2015-03-25 13:09:37'),
(327, 'PAR0259', '$2a$10$mnCqdTd7DyBP8TSCq.eg.OFHhtOQaScAXMUJDBt1DTK6QUAvlPNPu', 'NNOROM MIRACLE', 259, 'sponsors/259.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 02:18:48', '2015-03-25 13:18:48'),
(328, 'PAR0260', '$2a$10$7X3QMeSfDrZTFn.xNbn63OTXR32PtxqYJwKZMJ5N9fLkUMDHQLuym', 'OGBECHIE CHIDIEBUBE', 260, 'sponsors/260.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 02:20:16', '2015-03-25 13:20:17'),
(329, 'PAR0261', '$2a$10$INGn14v9.eUipVRuYA2UKezn.hAxHmiU0aNeYWlLWNiItPiTadQCy', 'OKEREAFOR EBUBE', 261, 'sponsors/261.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 02:23:04', '2015-03-25 13:23:04'),
(330, 'PAR0262', '$2a$10$.EbrPGaeJctgzzn7AVItZO6og9sGMxrmAzKlhsl8yvRGmo1LeslYy', 'OLANIYONU OLADIPO', 262, 'sponsors/262.jpg', 1, 'PAR_USERS', 1, 0, '2015-03-26 04:37:15', '2015-03-26 15:37:15'),
(331, 'PAR0263', '$2a$10$8KgpMnOK8EeWf6rR70M4v.xIpWuIqDeKGzZ5dlbnFn16oNJpkeKjW', 'UNAH RINCHA', 263, 'sponsors/263.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 02:33:42', '2015-03-25 13:33:42'),
(332, 'PAR0264', '$2a$10$DvCvHnd3wF8/WWsihDR/e.J0Qx4kaB1CgqoEKzIXnfIiklqpEvpca', 'IGWE CHUKWURAH', 264, 'sponsors/264.jpg', 1, 'PAR_USERS', 1, 32, '2015-03-25 04:23:23', '2015-03-25 15:23:23'),
(333, 'PAR0265', '$2a$10$.kC22bkJbwL4pP5QvcYIae4pOybX4oiYA4bLTpL.74NJN436Rri1y', 'OBIDIEGWU DANIEL', 265, 'sponsors/265.jpg', 1, 'PAR_USERS', 1, 32, '2015-03-25 04:24:43', '2015-03-25 15:24:43'),
(334, 'PAR0266', '$2a$10$.lfp0nNz2cOsC8joqOLcweD1/hjCNOFDMpGS0wTMHJ8zSBpcBDLz2', 'AGBAWHE MATTHEW', 266, 'sponsors/266.jpg', 1, 'PAR_USERS', 1, 32, '2015-03-25 04:27:08', '2015-03-25 15:27:08'),
(335, 'PAR0267', '$2a$10$XtK5WsUO7jn2I2sVJc8g4OQkFeT.F9AMmN1GUkVi5pjNPyeSmqz3y', 'ASAKITIPI ALEX', 267, 'sponsors/267.jpg', 1, 'PAR_USERS', 1, 32, '2015-03-25 04:29:25', '2015-03-25 15:29:25'),
(336, 'PAR0268', '$2a$10$SsJfJpt/YMjQqoWa0N7LGeJyXF7HHOKYyGGnFrzSFWJAfQb4ltHl6', 'ODESANYA KOREDE', 268, 'sponsors/268.jpg', 1, 'PAR_USERS', 1, 59, '2015-03-25 04:47:56', '2015-03-25 15:47:57'),
(337, 'PAR0269', '$2a$10$8PCasMQfzC0ea4QOfZMTCe.x5Z/2V.rmSTnyBN24i6m6vxG0jVE0q', 'OSHINAIKE TEMILOLUWA', 269, 'sponsors/269.jpg', 1, 'PAR_USERS', 1, 59, '2015-03-25 04:54:09', '2015-03-25 15:54:09'),
(338, 'PAR0270', '$2a$10$ObgRe/mfgTMltfatbYZ46OXYEIIRdTaCD7RETJMOqgC2nuim71CHO', 'TOOGUN YEWANDE', 270, 'sponsors/270.jpg', 1, 'PAR_USERS', 1, 59, '2015-03-25 04:55:22', '2015-03-25 15:55:23'),
(339, 'PAR0271', '$2a$10$Oo1VSJfbb5QaGXigWSzrWe4oKfyPZw1An7zoAZC8SUNHbN2Rr27wK', 'ENI JEREMIAH', 271, 'sponsors/271.jpg', 1, 'PAR_USERS', 1, 59, '2015-03-25 04:57:12', '2015-03-25 15:57:13'),
(340, 'PAR0272', '$2a$10$FCuLl/wak6z/vhDQeqLCIeXNA/U2R69KXsq/lmOWEFDEkrrcJYU4m', 'OPARA HOPE', 272, 'sponsors/272.jpg', 1, 'PAR_USERS', 1, 32, '2015-03-25 05:07:48', '2015-03-25 16:07:49'),
(341, 'STF0067', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'SU .', 67, 'employees/67.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-26 09:29:04', '2015-03-26 08:29:04'),
(342, 'PAR0273', '$2a$10$8i9ekrmYYX0PnmmhUVnLO.lT0MwqV9c2rpZs94wnPod4kst.hJhbC', 'NICHOLAS DAAIYEFUMASU', 273, 'sponsors/273.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-26 12:22:49', '2015-03-26 11:22:49');

-- --------------------------------------------------------

--
-- Structure for view `attend_headerviews`
--
DROP TABLE IF EXISTS `attend_headerviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `attend_headerviews` AS select `a`.`attend_id` AS `attend_id`,`a`.`class_id` AS `class_id`,`a`.`employee_id` AS `employee_id`,`a`.`academic_term_id` AS `academic_term_id`,`a`.`attend_date` AS `attend_date`,`b`.`class_name` AS `class_name`,`b`.`classlevel_id` AS `classlevel_id`,`c`.`academic_term` AS `academic_term`,`c`.`academic_year_id` AS `academic_year_id`,concat(ucase(`d`.`first_name`),' ',`d`.`other_name`) AS `head_tutor` from (((`attends` `a` join `classrooms` `b` on((`a`.`class_id` = `b`.`class_id`))) join `academic_terms` `c` on((`a`.`academic_term_id` = `c`.`academic_term_id`))) join `employees` `d` on((`a`.`employee_id` = `d`.`employee_id`)));

-- --------------------------------------------------------

--
-- Structure for view `classroom_subjectregisterviews`
--
DROP TABLE IF EXISTS `classroom_subjectregisterviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `classroom_subjectregisterviews` AS select `a`.`student_id` AS `student_id`,`a`.`class_id` AS `class_id`,`a`.`subject_classlevel_id` AS `subject_classlevel_id`,`b`.`subject_id` AS `subject_id`,`b`.`academic_term_id` AS `academic_term_id`,`b`.`examstatus_id` AS `examstatus_id`,`c`.`classlevel_id` AS `classlevel_id`,`c`.`class_name` AS `class_name` from ((`subject_students_registers` `a` join `subject_classlevels` `b` on((`a`.`subject_classlevel_id` = `b`.`subject_classlevel_id`))) join `classrooms` `c` on((`a`.`class_id` = `c`.`class_id`))) group by `a`.`class_id`,`a`.`subject_classlevel_id`;

-- --------------------------------------------------------

--
-- Structure for view `exam_subjectviews`
--
DROP TABLE IF EXISTS `exam_subjectviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `exam_subjectviews` AS select `a`.`exam_id` AS `exam_id`,`a`.`class_id` AS `class_id`,`f`.`class_name` AS `class_name`,`c`.`subject_name` AS `subject_name`,`b`.`subject_id` AS `subject_id`,`a`.`subject_classlevel_id` AS `subject_classlevel_id`,`h`.`weightageCA1` AS `weightageCA1`,`h`.`weightageCA2` AS `weightageCA2`,`h`.`weightageExam` AS `weightageExam`,`a`.`exammarked_status_id` AS `exammarked_status_id`,`f`.`classlevel_id` AS `classlevel_id`,`g`.`classlevel` AS `classlevel`,`b`.`academic_term_id` AS `academic_term_id`,`d`.`academic_term` AS `academic_term`,`d`.`academic_year_id` AS `academic_year_id`,`e`.`academic_year` AS `academic_year` from ((((((`exams` `a` left join (`classlevels` `g` join `classrooms` `f` on((`f`.`classlevel_id` = `g`.`classlevel_id`))) on((`a`.`class_id` = `f`.`class_id`))) join `subject_classlevels` `b` on((`a`.`subject_classlevel_id` = `b`.`subject_classlevel_id`))) join `subjects` `c` on((`b`.`subject_id` = `c`.`subject_id`))) join `academic_terms` `d` on((`b`.`academic_term_id` = `d`.`academic_term_id`))) join `academic_years` `e` on((`d`.`academic_year_id` = `e`.`academic_year_id`))) join `classgroups` `h` on((`g`.`classgroup_id` = `h`.`classgroup_id`)));

-- --------------------------------------------------------

--
-- Structure for view `examsdetails_reportviews`
--
DROP TABLE IF EXISTS `examsdetails_reportviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `examsdetails_reportviews` AS select `exams`.`exam_id` AS `exam_id`,`subject_classlevels`.`subject_id` AS `subject_id`,`subject_classlevels`.`classlevel_id` AS `classlevel_id`,`classrooms`.`class_id` AS `class_id`,`students`.`student_id` AS `student_id`,`subjects`.`subject_name` AS `subject_name`,`classrooms`.`class_name` AS `class_name`,concat(ucase(`students`.`first_name`),' ',lcase(`students`.`surname`),' ',lcase(`students`.`other_name`)) AS `student_fullname`,`exam_details`.`ca1` AS `ca1`,`exam_details`.`ca2` AS `ca2`,`exam_details`.`exam` AS `exam`,`classgroups`.`weightageCA1` AS `weightageCA1`,`classgroups`.`weightageCA2` AS `weightageCA2`,`classgroups`.`weightageExam` AS `weightageExam`,`academic_terms`.`academic_term_id` AS `academic_term_id`,`academic_terms`.`academic_term` AS `academic_term`,`exams`.`exammarked_status_id` AS `exammarked_status_id`,`academic_terms`.`academic_year_id` AS `academic_year_id`,`academic_years`.`academic_year` AS `academic_year`,`classlevels`.`classlevel` AS `classlevel`,`classlevels`.`classgroup_id` AS `classgroup_id` from ((((((((((`exams` join `exam_details` on((`exams`.`exam_id` = `exam_details`.`exam_id`))) join `subject_classlevels` on((`exams`.`subject_classlevel_id` = `subject_classlevels`.`subject_classlevel_id`))) join `subjects` on((`subject_classlevels`.`subject_id` = `subjects`.`subject_id`))) join `students` on((`exam_details`.`student_id` = `students`.`student_id`))) join `academic_terms` on((`subject_classlevels`.`academic_term_id` = `academic_terms`.`academic_term_id`))) join `academic_years` on((`academic_years`.`academic_year_id` = `academic_terms`.`academic_year_id`))) join `classlevels` on((`subject_classlevels`.`classlevel_id` = `classlevels`.`classlevel_id`))) join `students_classes` on((`students`.`student_id` = `students_classes`.`student_id`))) join `classrooms` on((`students_classes`.`class_id` = `classrooms`.`class_id`))) join `classgroups` on((`classgroups`.`classgroup_id` = `classlevels`.`classgroup_id`)));

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

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `students_subjectsviews` AS select `a`.`student_id` AS `student_id`,`a`.`class_id` AS `class_id`,`a`.`subject_classlevel_id` AS `subject_classlevel_id`,concat(ucase(`b`.`first_name`),', ',`b`.`surname`,' ',`b`.`other_name`) AS `student_name`,`b`.`student_no` AS `student_no`,`c`.`class_name` AS `class_name`,`e`.`subject_id` AS `subject_id`,`f`.`subject_name` AS `subject_name`,`c`.`classlevel_id` AS `classlevel_id`,`d`.`classlevel` AS `classlevel` from (((((`subject_students_registers` `a` join `students` `b` on((`a`.`student_id` = `b`.`student_id`))) join `classrooms` `c` on((`a`.`class_id` = `c`.`class_id`))) join `classlevels` `d` on((`c`.`classlevel_id` = `d`.`classlevel_id`))) join `subject_classlevels` `e` on((`e`.`subject_classlevel_id` = `a`.`subject_classlevel_id`))) join `subjects` `f` on((`f`.`subject_id` = `e`.`subject_id`)));

-- --------------------------------------------------------

--
-- Structure for view `subject_classlevelviews`
--
DROP TABLE IF EXISTS `subject_classlevelviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `subject_classlevelviews` AS select `classrooms`.`class_name` AS `class_name`,`subjects`.`subject_name` AS `subject_name`,`subjects`.`subject_id` AS `subject_id`,`classrooms`.`class_id` AS `class_id`,`classlevels`.`classlevel_id` AS `classlevel_id`,`subject_classlevels`.`subject_classlevel_id` AS `subject_classlevel_id`,`classlevels`.`classlevel` AS `classlevel`,`subject_classlevels`.`examstatus_id` AS `examstatus_id`,(case `subject_classlevels`.`examstatus_id` when 1 then 'Already Setup' when 2 then 'Not Setup' end) AS `exam_status`,`subject_classlevels`.`academic_term_id` AS `academic_term_id`,`academic_terms`.`academic_term` AS `academic_term`,`academic_terms`.`academic_year_id` AS `academic_year_id`,`academic_years`.`academic_year` AS `academic_year` from (((((`subject_classlevels` join `academic_terms` on((`subject_classlevels`.`academic_term_id` = `academic_terms`.`academic_term_id`))) join `academic_years` on((`academic_terms`.`academic_year_id` = `academic_years`.`academic_year_id`))) left join `classrooms` on((`subject_classlevels`.`class_id` = `classrooms`.`class_id`))) left join `classlevels` on((`subject_classlevels`.`classlevel_id` = `classlevels`.`classlevel_id`))) left join `subjects` on((`subject_classlevels`.`subject_id` = `subjects`.`subject_id`)));

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
 ADD PRIMARY KEY (`assessment_id`), ADD KEY `student_id` (`student_id`), ADD KEY `academic_term_id` (`academic_term_id`);

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
 ADD PRIMARY KEY (`employee_qualification_id`), ADD KEY `employee_id` (`employee_id`);

--
-- Indexes for table `employee_types`
--
ALTER TABLE `employee_types`
 ADD PRIMARY KEY (`employee_type_id`);

--
-- Indexes for table `employees`
--
ALTER TABLE `employees`
 ADD PRIMARY KEY (`employee_id`), ADD KEY `salutation_id` (`salutation_id`), ADD KEY `employee_type_id` (`employee_type_id`), ADD KEY `state_id` (`state_id`), ADD KEY `local_govt_id` (`local_govt_id`);

--
-- Indexes for table `exam_details`
--
ALTER TABLE `exam_details`
 ADD PRIMARY KEY (`exam_detail_id`), ADD KEY `exam_id` (`exam_id`,`student_id`);

--
-- Indexes for table `exams`
--
ALTER TABLE `exams`
 ADD PRIMARY KEY (`exam_id`), ADD KEY `class_id` (`class_id`);

--
-- Indexes for table `grades`
--
ALTER TABLE `grades`
 ADD PRIMARY KEY (`grades_id`), ADD KEY `classgroup_id` (`classgroup_id`);

--
-- Indexes for table `item_bills`
--
ALTER TABLE `item_bills`
 ADD PRIMARY KEY (`item_bill_id`), ADD KEY `item_id` (`item_id`,`classlevel_id`);

--
-- Indexes for table `item_types`
--
ALTER TABLE `item_types`
 ADD PRIMARY KEY (`item_type_id`);

--
-- Indexes for table `item_variables`
--
ALTER TABLE `item_variables`
 ADD PRIMARY KEY (`item_variable_id`), ADD KEY `item_id` (`item_id`,`student_id`,`class_id`,`academic_term_id`);

--
-- Indexes for table `items`
--
ALTER TABLE `items`
 ADD PRIMARY KEY (`item_id`), ADD KEY `item_type_id` (`item_type_id`);

--
-- Indexes for table `local_govts`
--
ALTER TABLE `local_govts`
 ADD PRIMARY KEY (`local_govt_id`), ADD KEY `state_id` (`state_id`);

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
 ADD PRIMARY KEY (`order_item_id`), ADD KEY `item_id` (`item_id`,`order_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
 ADD PRIMARY KEY (`order_id`), ADD KEY `student_id` (`student_id`,`sponsor_id`,`academic_term_id`,`process_item_id`);

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
-- Indexes for table `remarks`
--
ALTER TABLE `remarks`
 ADD PRIMARY KEY (`remark_id`);

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
 ADD PRIMARY KEY (`skill_assessment_id`), ADD KEY `skill_id` (`skill_id`,`assessment_id`);

--
-- Indexes for table `skills`
--
ALTER TABLE `skills`
 ADD PRIMARY KEY (`skill_id`);

--
-- Indexes for table `sponsors`
--
ALTER TABLE `sponsors`
 ADD PRIMARY KEY (`sponsor_id`), ADD KEY `salutation_id` (`salutation_id`,`local_govt_id`,`state_id`,`sponsorship_type_id`,`country_id`);

--
-- Indexes for table `sponsorship_types`
--
ALTER TABLE `sponsorship_types`
 ADD PRIMARY KEY (`sponsorship_type_id`);

--
-- Indexes for table `spouse_details`
--
ALTER TABLE `spouse_details`
 ADD PRIMARY KEY (`spouse_detail_id`), ADD KEY `employee_id` (`employee_id`);

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
 ADD PRIMARY KEY (`student_id`), ADD KEY `class_id` (`class_id`,`academic_term_id`,`local_govt_id`,`student_status_id`,`state_id`,`country_id`,`relationtype_id`);

--
-- Indexes for table `students_classes`
--
ALTER TABLE `students_classes`
 ADD PRIMARY KEY (`student_class_id`), ADD KEY `student_id` (`student_id`,`class_id`,`academic_year_id`);

--
-- Indexes for table `subject_classlevels`
--
ALTER TABLE `subject_classlevels`
 ADD PRIMARY KEY (`subject_classlevel_id`), ADD KEY `subject_id` (`subject_id`,`classlevel_id`,`class_id`,`academic_term_id`,`examstatus_id`);

--
-- Indexes for table `subject_groups`
--
ALTER TABLE `subject_groups`
 ADD PRIMARY KEY (`subject_group_id`);

--
-- Indexes for table `subject_students_registers`
--
ALTER TABLE `subject_students_registers`
 ADD KEY `student_id` (`student_id`,`class_id`,`subject_classlevel_id`);

--
-- Indexes for table `subjects`
--
ALTER TABLE `subjects`
 ADD PRIMARY KEY (`subject_id`), ADD KEY `subject_group_id` (`subject_group_id`);

--
-- Indexes for table `teachers_classes`
--
ALTER TABLE `teachers_classes`
 ADD PRIMARY KEY (`teacher_class_id`), ADD KEY `class_id` (`class_id`,`employee_id`,`academic_year_id`);

--
-- Indexes for table `teachers_subjects`
--
ALTER TABLE `teachers_subjects`
 ADD PRIMARY KEY (`teachers_subjects_id`), ADD KEY `employee_id` (`employee_id`,`class_id`,`subject_classlevel_id`);

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
MODIFY `academic_term_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `academic_years`
--
ALTER TABLE `academic_years`
MODIFY `academic_year_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `acos`
--
ALTER TABLE `acos`
MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=157;
--
-- AUTO_INCREMENT for table `aros`
--
ALTER TABLE `aros`
MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `aros_acos`
--
ALTER TABLE `aros_acos`
MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=49;
--
-- AUTO_INCREMENT for table `assessments`
--
ALTER TABLE `assessments`
MODIFY `assessment_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `attends`
--
ALTER TABLE `attends`
MODIFY `attend_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `classgroups`
--
ALTER TABLE `classgroups`
MODIFY `classgroup_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `classlevels`
--
ALTER TABLE `classlevels`
MODIFY `classlevel_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `classrooms`
--
ALTER TABLE `classrooms`
MODIFY `class_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=31;
--
-- AUTO_INCREMENT for table `countries`
--
ALTER TABLE `countries`
MODIFY `country_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=234;
--
-- AUTO_INCREMENT for table `employee_qualifications`
--
ALTER TABLE `employee_qualifications`
MODIFY `employee_qualification_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `employee_types`
--
ALTER TABLE `employee_types`
MODIFY `employee_type_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `employees`
--
ALTER TABLE `employees`
MODIFY `employee_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=68;
--
-- AUTO_INCREMENT for table `exam_details`
--
ALTER TABLE `exam_details`
MODIFY `exam_detail_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=670;
--
-- AUTO_INCREMENT for table `exams`
--
ALTER TABLE `exams`
MODIFY `exam_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=55;
--
-- AUTO_INCREMENT for table `grades`
--
ALTER TABLE `grades`
MODIFY `grades_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=14;
--
-- AUTO_INCREMENT for table `item_bills`
--
ALTER TABLE `item_bills`
MODIFY `item_bill_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `item_types`
--
ALTER TABLE `item_types`
MODIFY `item_type_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `item_variables`
--
ALTER TABLE `item_variables`
MODIFY `item_variable_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `items`
--
ALTER TABLE `items`
MODIFY `item_id` int(11) NOT NULL AUTO_INCREMENT;
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
MODIFY `message_recipient_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
MODIFY `message_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
MODIFY `order_item_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `process_items`
--
ALTER TABLE `process_items`
MODIFY `process_item_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `relationship_types`
--
ALTER TABLE `relationship_types`
MODIFY `relationship_type_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=10;
--
-- AUTO_INCREMENT for table `remarks`
--
ALTER TABLE `remarks`
MODIFY `remark_id` int(11) NOT NULL AUTO_INCREMENT;
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
MODIFY `skill_assessment_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `skills`
--
ALTER TABLE `skills`
MODIFY `skill_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=18;
--
-- AUTO_INCREMENT for table `sponsors`
--
ALTER TABLE `sponsors`
MODIFY `sponsor_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=274;
--
-- AUTO_INCREMENT for table `sponsorship_types`
--
ALTER TABLE `sponsorship_types`
MODIFY `sponsorship_type_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `spouse_details`
--
ALTER TABLE `spouse_details`
MODIFY `spouse_detail_id` int(11) NOT NULL AUTO_INCREMENT;
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
MODIFY `student_id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=286;
--
-- AUTO_INCREMENT for table `students_classes`
--
ALTER TABLE `students_classes`
MODIFY `student_class_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=288;
--
-- AUTO_INCREMENT for table `subject_classlevels`
--
ALTER TABLE `subject_classlevels`
MODIFY `subject_classlevel_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=198;
--
-- AUTO_INCREMENT for table `subject_groups`
--
ALTER TABLE `subject_groups`
MODIFY `subject_group_id` int(3) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `subjects`
--
ALTER TABLE `subjects`
MODIFY `subject_id` int(3) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=44;
--
-- AUTO_INCREMENT for table `teachers_classes`
--
ALTER TABLE `teachers_classes`
MODIFY `teacher_class_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=23;
--
-- AUTO_INCREMENT for table `teachers_subjects`
--
ALTER TABLE `teachers_subjects`
MODIFY `teachers_subjects_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=515;
--
-- AUTO_INCREMENT for table `user_roles`
--
ALTER TABLE `user_roles`
MODIFY `user_role_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
MODIFY `user_id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=343;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
