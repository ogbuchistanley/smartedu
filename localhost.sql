-- phpMyAdmin SQL Dump
-- version 4.2.7.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: May 06, 2015 at 06:49 PM
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

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `proc_annualClassPositionViews`$$
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

DROP PROCEDURE IF EXISTS `proc_assignSubject2Classlevels`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_assignSubject2Classlevels`(IN `LevelID` INT, `TermID` INT, `SubjectIDs` VARCHAR(225))
BEGIN 
	DECLARE done1 BOOLEAN DEFAULT FALSE;
	DECLARE ClassID INT;
	DECLARE cur1 CURSOR FOR SELECT class_id FROM classrooms WHERE classlevel_id=LevelID;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;

	#Open The Cursor For Iterating Through The Recordset cur1
	OPEN cur1;
		REPEAT
		FETCH cur1 INTO ClassID;
			IF NOT done1 THEN	
				BEGIN
					-- Procedure Call -- To register the subjects to the students in that classroom 
					CALL `proc_assignSubject2Classrooms`(ClassID, LevelID, TermID, SubjectIDs);
				END;
			END IF;
		UNTIL done1 END REPEAT;
	CLOSE cur1;	
END$$

DROP PROCEDURE IF EXISTS `proc_assignSubject2Classrooms`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_assignSubject2Classrooms`(IN `ClassID` INT, `LevelID` INT, `TermID` INT, `SubjectIDs` VARCHAR(225))
BEGIN 
	#Create a Temporary Table to Hold The Values
	DROP TEMPORARY TABLE IF EXISTS SubjectTemp;
	CREATE TEMPORARY TABLE IF NOT EXISTS SubjectTemp 
	(
		-- Add the column definitions for the TABLE variable here
		row_id int AUTO_INCREMENT,
		subject_id INT, PRIMARY KEY (row_id)
	);

	IF SubjectIDs IS NOT NULL THEN
		BEGIN
			DECLARE count INT Default 0 ;
			DECLARE subject_id VARCHAR(255);
			simple_loop: LOOP
				SET count = count + 1;
				SET subject_id = SPLIT_STR(SubjectIDs, ',', count);
				IF subject_id = '' THEN
					LEAVE simple_loop;
				END IF;
				# Insert into the attend details table those present
				INSERT INTO SubjectTemp(subject_id)
				SELECT subject_id;
		   END LOOP simple_loop;
		END;
	END IF;

	Block1: BEGIN
		DELETE FROM subject_students_registers WHERE subject_classlevel_id IN
		(
			SELECT subject_classlevel_id FROM subject_classlevels WHERE class_id=ClassID AND classlevel_id=LevelID AND academic_term_id=TermID AND subject_id NOT IN 
			(SELECT subject_id FROM SubjectTemp)
		);

		DELETE FROM subject_classlevels WHERE class_id=ClassID AND classlevel_id=LevelID AND academic_term_id=TermID AND subject_id NOT IN 
		(SELECT subject_id FROM SubjectTemp);
		
        Block2: BEGIN								
			DECLARE done1 BOOLEAN DEFAULT FALSE;
			DECLARE SubjectID INT;
			DECLARE cur1 CURSOR FOR SELECT subject_id FROM SubjectTemp;
			DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;
		
			#Open The Cursor For Iterating Through The Recordset cur1
			OPEN cur1;
				REPEAT
				FETCH cur1 INTO SubjectID;
					IF NOT done1 THEN	
						BEGIN
							SET @Exist = (SELECT COUNT(*) FROM subject_classlevels WHERE subject_id=SubjectID AND class_id=ClassID AND classlevel_id=LevelID AND academic_term_id=TermID); 
							IF @Exist = 0 THEN
								BEGIN
									# Insert into subject classlevel those newly assigned subjects
									INSERT INTO subject_classlevels(subject_id, classlevel_id, class_id, academic_term_id)
									VALUES(SubjectID, LevelID, ClassID, TermID);
                                    
                                    -- Procedure Call -- To register the subjects to the students in that classroom 
									CALL proc_assignSubject2Students(LAST_INSERT_ID());
								END;
							END IF;
						END;
					END IF;
				UNTIL done1 END REPEAT;
			CLOSE cur1;								
		END Block2;
	END Block1;	
END$$

DROP PROCEDURE IF EXISTS `proc_assignSubject2Students`$$
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

DROP PROCEDURE IF EXISTS `proc_examsDetailsReportViews`$$
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

DROP PROCEDURE IF EXISTS `proc_insertAttendDetails`$$
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

DROP PROCEDURE IF EXISTS `proc_insertWeeklyReportDetail`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_insertWeeklyReportDetail`(IN `WeeklyReportID` INT)
BEGIN
	# Delete The Record if it exists
	SELECT weekly_detail_setup_id, subject_classlevel_id, marked_status, notification_status 
    INTO @WDS_ID, @SCL_ID, @MStatus, @NStatus 
    FROM weekly_reports WHERE weekly_report_id=WeeklyReportID;
    
    # Check if the weekly report has been marked before
	IF @NStatus = 2 THEN
		BEGIN
			# Insert into the weekly reports details table the students
            INSERT INTO weekly_report_details(weekly_report_id, student_id)
			SELECT WeeklyReportID, student_id FROM subject_students_registers WHERE subject_classlevel_id=@SCL_ID
            AND student_id NOT IN (SELECT student_id FROM weekly_report_details WHERE weekly_report_id=WeeklyReportID);
            
			# remove the students that was just removed from the list of students to offer the subject
			DELETE FROM weekly_report_details WHERE weekly_report_id=WeeklyReportID AND student_id NOT IN 
			(SELECT student_id FROM subject_students_registers WHERE subject_classlevel_id=@SCL_ID);
		END;
	END IF;
END$$

DROP PROCEDURE IF EXISTS `proc_processExams`$$
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

DROP PROCEDURE IF EXISTS `proc_processItemVariable`$$
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

DROP PROCEDURE IF EXISTS `proc_processTerminalFees`$$
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

DROP PROCEDURE IF EXISTS `proc_terminalClassPositionViews`$$
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
DROP FUNCTION IF EXISTS `func_annualExamsViews`$$
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

DROP FUNCTION IF EXISTS `fun_getAttendSummary`$$
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

DROP FUNCTION IF EXISTS `fun_getClassHeadTutor`$$
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

DROP FUNCTION IF EXISTS `fun_getClasslevelSub`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `fun_getClasslevelSub`(`TermID` INT, `LevelID` INT) RETURNS int(11)
    DETERMINISTIC
Block0: BEGIN
	SET @Output = 0;
	#Create a Temporary Table to Hold The Values
	DROP TEMPORARY TABLE IF EXISTS SubjectClasslevelTemp;
	CREATE TEMPORARY TABLE IF NOT EXISTS SubjectClasslevelTemp 
	(
		-- Add the column definitions for the TABLE variable here
		row_id INT AUTO_INCREMENT,
		subject_id INT,
		subject_name VARCHAR(50),
		academic_term_id INT,
		academic_term VARCHAR(50),
		class_id INT,
		class_name VARCHAR(50),
		classlevel_id INT,
		classlevel VARCHAR(50), PRIMARY KEY (row_id)
	);
    
    Block2: BEGIN								
		DECLARE done1 BOOLEAN DEFAULT FALSE;
		DECLARE SubjectID, ClassID, ClasslevelID, AcademicID  INT;
		DECLARE SubjectName, ClassName, AcademicTerm VARCHAR(50);
		DECLARE cur1 CURSOR FOR SELECT subject_id, class_id, classlevel_id, academic_term_id, subject_name, class_name, academic_term 
		FROM subject_classlevelviews WHERE academic_term_id=TermID AND classlevel_id=LevelID GROUP BY subject_id ORDER BY subject_name;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;
	
		#Open The Cursor For Iterating Through The Recordset cur1
		OPEN cur1;
			REPEAT
			FETCH cur1 INTO SubjectID, ClassID, ClasslevelID, AcademicID, SubjectName, ClassName, AcademicTerm;
				IF NOT done1 THEN
					BEGIN
						SET @ClassInLevel = (SELECT COUNT(*) FROM classrooms WHERE classlevel_id=LevelID);
						SET @SubjectInLevel = (SELECT COUNT(*) FROM subject_classlevelviews a WHERE academic_term_id=TermID AND classlevel_id=LevelID AND subject_id=SubjectID);

						IF @ClassInLevel = @SubjectInLevel THEN
							-- Insert into the resultant table that will display the results
							INSERT INTO SubjectClasslevelTemp(subject_id, subject_name, academic_term_id, academic_term, class_id, class_name, classlevel_id, classlevel) 
                            VALUES(SubjectID, SubjectName, AcademicID, AcademicTerm, ClassID, ClassName, ClasslevelID, classlevel);	
						END IF;
					END;
				END IF;
			UNTIL done1 END REPEAT;
		CLOSE cur1;								
	END Block2;	

	SET @Output = (SELECT COUNT(*) FROM SubjectClasslevelTemp);
	RETURN @Output;
END Block0$$

DROP FUNCTION IF EXISTS `fun_getSubjectClasslevel`$$
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

DROP FUNCTION IF EXISTS `getCurrentTermID`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getCurrentTermID`() RETURNS int(11)
BEGIN
	RETURN (SELECT academic_term_id FROM academic_terms WHERE term_status_id=1 LIMIT 1);
END$$

DROP FUNCTION IF EXISTS `getCurrentYearID`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `getCurrentYearID`() RETURNS int(11)
BEGIN
	RETURN (SELECT academic_year_id FROM academic_years WHERE year_status_id=1 LIMIT 1);	
END$$

DROP FUNCTION IF EXISTS `SPLIT_STR`$$
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

DROP TABLE IF EXISTS `academic_terms`;
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

DROP TABLE IF EXISTS `academic_years`;
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

DROP TABLE IF EXISTS `acos`;
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

DROP TABLE IF EXISTS `aros`;
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

DROP TABLE IF EXISTS `aros_acos`;
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

DROP TABLE IF EXISTS `assessments`;
CREATE TABLE IF NOT EXISTS `assessments` (
`assessment_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `academic_term_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `attend_details`
--

DROP TABLE IF EXISTS `attend_details`;
CREATE TABLE IF NOT EXISTS `attend_details` (
  `student_id` int(11) DEFAULT NULL,
  `attend_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Stand-in structure for view `attend_headerviews`
--
DROP VIEW IF EXISTS `attend_headerviews`;
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

DROP TABLE IF EXISTS `attends`;
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

DROP TABLE IF EXISTS `classgroups`;
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

DROP TABLE IF EXISTS `classlevels`;
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
DROP VIEW IF EXISTS `classroom_subjectregisterviews`;
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

DROP TABLE IF EXISTS `classrooms`;
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

DROP TABLE IF EXISTS `countries`;
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

DROP TABLE IF EXISTS `employee_qualifications`;
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

DROP TABLE IF EXISTS `employee_types`;
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

DROP TABLE IF EXISTS `employees`;
CREATE TABLE IF NOT EXISTS `employees` (
`employee_id` int(11) NOT NULL,
  `employee_no` varchar(10) NOT NULL,
  `salutation_id` int(10) unsigned DEFAULT NULL,
  `first_name` varchar(100) DEFAULT NULL,
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

INSERT INTO `employees` (`employee_id`, `employee_no`, `salutation_id`, `first_name`, `other_name`, `gender`, `birth_date`, `image_url`, `contact_address`, `employee_type_id`, `mobile_number1`, `mobile_number2`, `marital_status`, `country_id`, `state_id`, `local_govt_id`, `email`, `next_ofkin_name`, `next_ofkin_number`, `next_ofkin_relate`, `form_of_identity`, `identity_no`, `identity_expiry_date`, `status_id`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'STF0001', 1, 'Dotun', 'Kudaisi', 'Male', '2015-03-03', 'employees/1.png', 'iofdi', NULL, '08052139529', '', 'Single', 140, 5, NULL, 'dotman2kx@gmail.com', 'djj', '08019189298', 'jdfhjdfh', '', '', '1970-01-01', 1, 1, '2015-03-19 02:16:59', '2015-03-24 16:05:02'),
(3, 'STF0003', 1, 'Abikoye', 'J.', NULL, NULL, NULL, NULL, NULL, '07035376722', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:40:35', '2015-03-21 10:03:50'),
(4, 'STF0004', 1, 'ADEGOKE', 'M.', NULL, NULL, NULL, NULL, NULL, '07033895470', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:42:34', '2015-03-21 13:08:24'),
(5, 'STF0005', 1, 'ADEYEMI', 'B.', NULL, NULL, NULL, NULL, NULL, '08068891010', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:47:32', '2015-03-21 13:03:47'),
(6, 'STF0006', 1, 'ADISA', 'S.', NULL, NULL, NULL, NULL, NULL, '08062915800', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:48:42', '2015-03-21 13:03:05'),
(7, 'STF0007', 1, 'AIGBOMIAN', 'A.', NULL, NULL, NULL, NULL, NULL, '07062371754', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:49:44', '2015-03-21 13:02:06'),
(8, 'STF0008', 1, 'AJAYI', 'G.', NULL, NULL, NULL, NULL, NULL, '08060132925', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:53:19', '2015-03-21 13:01:37'),
(9, 'STF0009', 1, 'AKINROLABU', 'B.', NULL, NULL, NULL, NULL, NULL, '08068578087', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:57:44', '2015-03-21 13:00:42'),
(10, 'STF0010', 1, 'AKINYEMI', 'D.', NULL, NULL, NULL, NULL, NULL, '08034497060', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:58:39', '2015-03-21 12:57:44'),
(11, 'STF0011', 4, 'ALIU', 'Z.', NULL, NULL, NULL, NULL, NULL, '08033426503', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 06:59:28', '2015-03-21 12:55:51'),
(12, 'STF0012', 1, 'ANJORIN', 'A.', NULL, NULL, NULL, NULL, NULL, '08130113255', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:00:59', '2015-03-21 12:54:52'),
(13, 'STF0013', 1, 'ARAOYE', 'O.', NULL, NULL, NULL, NULL, NULL, '08028274106', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:02:00', '2015-03-21 12:53:50'),
(14, 'STF0014', 3, 'AWOGBADE', 'A.', NULL, NULL, NULL, NULL, NULL, '07064818193', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:03:50', '2015-03-21 12:53:17'),
(15, 'STF0015', 4, 'AYEGBUSI', 'ADERONKE', NULL, NULL, NULL, NULL, NULL, '08033877116', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:05:29', '2015-03-21 12:51:24'),
(16, 'STF0016', 4, 'AZEEZ', 'B.', NULL, NULL, NULL, NULL, NULL, '08063533814', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:06:03', '2015-03-21 12:50:48'),
(17, 'STF0017', 4, 'AZIAKA', 'D.', NULL, NULL, NULL, NULL, NULL, '08061697111', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:07:31', '2015-03-21 12:46:34'),
(18, 'STF0018', 4, 'BABALOLA', 'A.', NULL, NULL, NULL, NULL, NULL, '07031233376', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:08:50', '2015-03-21 12:41:48'),
(19, 'STF0019', 4, 'BABATOPE', 'F.', NULL, NULL, NULL, NULL, NULL, '08023629883', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:12:59', '2015-03-21 12:42:21'),
(20, 'STF0020', 4, 'BADERIN', '.', NULL, NULL, NULL, NULL, NULL, '08027282096', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:14:15', '2015-03-21 12:29:19'),
(21, 'STF0021', 1, 'BETIKU', 'INCREASE ', NULL, NULL, NULL, NULL, NULL, '08035714860', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:14:58', '2015-03-21 12:25:18'),
(22, 'STF0022', 1, 'DADA', 'B.', NULL, NULL, NULL, NULL, NULL, '08023979489', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:17:57', '2015-03-21 12:23:51'),
(23, 'STF0023', 4, 'EKPUH', 'M.', NULL, NULL, NULL, NULL, NULL, '08104942760', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:36:44', '2015-03-21 12:21:37'),
(24, 'STF0024', 1, 'EKUNBOYEJO', 'E.', NULL, NULL, NULL, NULL, NULL, '08038321559', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:37:49', '2015-03-21 12:11:50'),
(25, 'STF0025', 1, 'EWERE', 'L.', NULL, NULL, NULL, NULL, NULL, '08160535011', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:39:13', '2015-03-21 12:08:48'),
(26, 'STF0026', 1, 'FAKOLUJO', 'E. ', NULL, NULL, NULL, NULL, NULL, '07057546505', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:39:46', '2015-03-21 11:54:01'),
(27, 'STF0027', 1, 'FAMAKINWA', 'J.', NULL, NULL, NULL, NULL, NULL, '07067834982', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:46:36', '2015-03-21 11:41:46'),
(28, 'STF0028', 1, 'GBADAMOSI', 'ABIODUN', NULL, NULL, NULL, NULL, NULL, '08027524466', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:50:51', '2015-03-21 11:37:09'),
(29, 'STF0029', 1, 'IBITAYO', 'M.', NULL, NULL, NULL, NULL, NULL, '08038330145', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:53:51', '2015-03-21 11:31:42'),
(30, 'STF0030', 3, 'IKEME', 'N.', NULL, NULL, NULL, NULL, NULL, '08137895592', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 07:57:25', '2015-03-21 11:28:57'),
(32, 'STF0032', 4, 'JOSEPH', 'F.', NULL, NULL, NULL, NULL, NULL, '07060828677', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 08:03:17', '2015-03-21 11:24:48'),
(33, 'STF0033', 1, 'KOLORUKO', 'L.', NULL, NULL, NULL, NULL, NULL, '08064797801', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 08:08:36', '2015-03-21 11:22:18'),
(34, 'STF0034', 1, 'LIADI', 'A.', NULL, NULL, NULL, NULL, NULL, '08062601861', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 08:10:38', '2015-03-21 11:19:14'),
(35, 'STF0035', 1, 'MEMUD', 'OLANREWAJU', NULL, NULL, NULL, NULL, NULL, '08053603925', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 08:11:09', '2015-03-21 11:08:32'),
(36, 'STF0036', 1, 'MUDASIRU', 'T.', NULL, NULL, NULL, NULL, NULL, '08060933502', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-19 08:15:50', '2015-03-21 11:05:51'),
(38, 'STF0038', 3, 'NOAH', 'F.', NULL, NULL, NULL, NULL, NULL, '08067297449', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, '2015-03-21 11:46:14', '2015-03-21 10:52:19'),
(39, 'STF0039', 1, 'NOSIKE', 'D.', NULL, NULL, NULL, NULL, NULL, '08063095009', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, '2015-03-21 12:00:40', '2015-03-21 11:00:40'),
(40, 'STF0040', 1, 'ADEOGUN', '.', NULL, NULL, NULL, NULL, NULL, '08135469418', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 02:12:36', '2015-03-21 13:12:36'),
(41, 'STF0041', 1, 'NWANI', ' J.', NULL, NULL, NULL, NULL, NULL, '07066363009', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:09:36', '2015-03-21 16:09:37'),
(42, 'STF0042', 1, 'NWANKWO', 'U.', NULL, NULL, NULL, NULL, NULL, '08068345230', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:10:54', '2015-03-21 16:10:54'),
(43, 'STF0043', 2, 'OBAJINMI', ' B.', NULL, NULL, NULL, NULL, NULL, '07041144695', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:12:34', '2015-03-21 16:19:07'),
(44, 'STF0044', 3, 'OBIANO', 'C.', NULL, NULL, NULL, NULL, NULL, '08037687230', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:13:13', '2015-03-21 16:13:13'),
(45, 'STF0045', 3, 'OGUNBOWALE', 'A.', NULL, NULL, NULL, NULL, NULL, '08034656573', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:15:41', '2015-03-21 16:15:41'),
(46, 'STF0046', 4, 'OGUNLEYE', 'M.', NULL, NULL, NULL, NULL, NULL, '08035824686', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:22:15', '2015-03-21 16:22:16'),
(47, 'STF0047', 3, 'OGUNSOLA', 'M.', NULL, NULL, NULL, NULL, NULL, '07064500449', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:24:14', '2015-03-21 16:24:14'),
(48, 'STF0048', 4, 'OJENIYI', 'A.', NULL, NULL, NULL, NULL, NULL, '08062253157', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:26:32', '2015-03-21 16:26:33'),
(49, 'STF0049', 1, 'OJETUNDE', 'S.', NULL, NULL, NULL, NULL, NULL, '08025532237', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:27:16', '2015-03-21 16:27:16'),
(50, 'STF0050', 1, 'OJO', 'T.', NULL, NULL, NULL, NULL, NULL, '08036284758', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:27:56', '2015-03-21 16:27:56'),
(51, 'STF0051', 4, 'OKECHUKWU-OMOLUABI', 'B.', NULL, NULL, NULL, NULL, NULL, '08069277582', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:30:43', '2015-03-21 16:30:43'),
(52, 'STF0052', 3, 'OKINI, ', 'I.', NULL, NULL, NULL, NULL, NULL, '07069524725', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:31:48', '2015-03-21 16:31:48'),
(53, 'STF0053', 3, 'OLAKANLE', 'O.', NULL, NULL, NULL, NULL, NULL, '08062690908', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:32:40', '2015-03-21 16:32:41'),
(54, 'STF0054', 4, 'OLATUNDE', 'T.', NULL, NULL, NULL, NULL, NULL, '08035059758', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:44:30', '2015-03-21 16:44:30'),
(55, 'STF0055', 1, 'OLAWOLE', 'O.', NULL, NULL, NULL, NULL, NULL, '08035059087', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:47:53', '2015-03-21 16:47:53'),
(56, 'STF0056', 1, 'ORIMOLADE', 'K.', NULL, NULL, NULL, NULL, NULL, '08035484885', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:48:44', '2015-03-21 16:48:44'),
(57, 'STF0057', 4, 'OWADOYE ', 'A.', NULL, NULL, NULL, NULL, NULL, '08034387875', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:49:38', '2015-03-21 16:49:38'),
(58, 'STF0058', 4, 'SOKOYA', 'T.', NULL, NULL, NULL, NULL, NULL, '08167452006', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:50:21', '2015-03-21 16:50:21'),
(59, 'STF0059', 4, 'TEMURU', 'S.', NULL, NULL, NULL, NULL, NULL, '08027315354', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:53:25', '2015-03-21 16:53:25'),
(60, 'STF0060', 1, 'UADEMEVBO', 'O.', NULL, NULL, NULL, NULL, NULL, '07033473699', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:55:03', '2015-03-21 16:55:03'),
(61, 'STF0061', 1, 'UDOKPORO', 'L.', NULL, NULL, NULL, NULL, NULL, '08029087555', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:55:54', '2015-03-21 16:55:54'),
(62, 'STF0062', 1, 'UMAR-MUHAMMED', 'A.', NULL, NULL, NULL, NULL, NULL, '07062052814', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:57:28', '2015-03-21 17:04:56'),
(63, 'STF0063', 3, 'USHIE', 'G.', NULL, NULL, NULL, NULL, NULL, '08038703859', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-21 05:59:08', '2015-03-21 16:59:08'),
(64, 'STF0064', 1, 'Okafor', 'Emmanuel', NULL, NULL, NULL, NULL, NULL, '08061539278', NULL, NULL, NULL, NULL, NULL, 'nondefyde@gmail.com', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-22 02:15:37', '2015-03-22 13:15:37'),
(65, 'STF0065', 3, 'Salau', '.', NULL, NULL, NULL, NULL, NULL, '08128560399', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-24 08:52:59', '2015-03-24 07:52:59'),
(66, 'STF0066', 1, 'ZIWORITIN', 'Ebikabo-Owei', NULL, NULL, NULL, NULL, NULL, '07062522236', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 43, '2015-03-25 11:46:52', '2015-03-25 10:46:52'),
(67, 'STF0067', 4, 'SU', '.', NULL, NULL, NULL, NULL, NULL, '08077863953', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-03-26 09:19:43', '2015-03-26 08:19:43');

-- --------------------------------------------------------

--
-- Table structure for table `exam_details`
--

DROP TABLE IF EXISTS `exam_details`;
CREATE TABLE IF NOT EXISTS `exam_details` (
`exam_detail_id` int(11) NOT NULL,
  `exam_id` int(11) DEFAULT NULL,
  `student_id` int(11) DEFAULT NULL,
  `ca1` decimal(4,1) DEFAULT '0.0',
  `ca2` decimal(4,1) DEFAULT '0.0',
  `exam` decimal(4,1) DEFAULT '0.0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `exam_subjectviews`
--
DROP VIEW IF EXISTS `exam_subjectviews`;
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

DROP TABLE IF EXISTS `exams`;
CREATE TABLE IF NOT EXISTS `exams` (
`exam_id` int(11) unsigned NOT NULL,
  `class_id` int(11) DEFAULT NULL,
  `subject_classlevel_id` int(11) DEFAULT NULL,
  `exammarked_status_id` int(11) DEFAULT '2'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `examsdetails_reportviews`
--
DROP VIEW IF EXISTS `examsdetails_reportviews`;
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

DROP TABLE IF EXISTS `grades`;
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

DROP TABLE IF EXISTS `item_bills`;
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

DROP TABLE IF EXISTS `item_types`;
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

DROP TABLE IF EXISTS `item_variables`;
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

DROP TABLE IF EXISTS `items`;
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

DROP TABLE IF EXISTS `local_govts`;
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

DROP TABLE IF EXISTS `master_setups`;
CREATE TABLE IF NOT EXISTS `master_setups` (
`master_setup_id` int(11) NOT NULL,
  `setup` varchar(30) NOT NULL DEFAULT 'smartedu',
  `master_record_id` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=2 ;

--
-- Dumping data for table `master_setups`
--

INSERT INTO `master_setups` (`master_setup_id`, `setup`, `master_record_id`) VALUES
(1, 'smartedu', 9);

-- --------------------------------------------------------

--
-- Table structure for table `message_recipients`
--

DROP TABLE IF EXISTS `message_recipients`;
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

DROP TABLE IF EXISTS `messages`;
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

DROP TABLE IF EXISTS `order_items`;
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

DROP TABLE IF EXISTS `orders`;
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

DROP TABLE IF EXISTS `process_items`;
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

DROP TABLE IF EXISTS `relationship_types`;
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

DROP TABLE IF EXISTS `remarks`;
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

DROP TABLE IF EXISTS `salutations`;
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

DROP TABLE IF EXISTS `setups`;
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

DROP TABLE IF EXISTS `skill_assessments`;
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

DROP TABLE IF EXISTS `skills`;
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

DROP TABLE IF EXISTS `sponsors`;
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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=274 ;

--
-- Dumping data for table `sponsors`
--

INSERT INTO `sponsors` (`sponsor_id`, `sponsor_no`, `first_name`, `other_name`, `salutation_id`, `occupation`, `company_name`, `company_address`, `email`, `image_url`, `contact_address`, `local_govt_id`, `state_id`, `country_id`, `mobile_number1`, `mobile_number2`, `created_by`, `sponsorship_type_id`, `created_at`, `updated_at`) VALUES
(1, 'PAR0001', 'Ogbuchi', 'Stanley', 1, NULL, NULL, NULL, 'ogbuchistanley@rocketmail.com', NULL, NULL, NULL, NULL, NULL, '08180966334', NULL, 1, NULL, '2015-03-19 02:11:34', '2015-03-19 13:11:34'),
(2, 'PAR0002', 'ADENIRAN', 'JOSEPH', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08055492870', NULL, 1, NULL, '2015-03-19 06:57:19', '2015-03-22 23:13:48'),
(3, 'PAR0003', 'ATUNRASE', 'BANKOLE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08028861077', NULL, 1, NULL, '2015-03-19 06:58:57', '2015-03-22 23:14:26'),
(4, 'PAR0004', 'BAIYEKUSI', 'PHOS BAYOWA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08088080606', NULL, 1, NULL, '2015-03-19 07:00:53', '2015-03-22 23:17:33'),
(5, 'PAR0005', 'BAKRE', 'OLUWATOFARATI DAVID', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023056956', NULL, 1, NULL, '2015-03-19 07:02:41', '2015-03-22 23:18:38'),
(6, 'PAR0006', 'BALOGUN', 'MOSES', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033249151', NULL, 1, NULL, '2015-03-19 07:04:50', '2015-03-22 23:19:33'),
(7, 'PAR0007', 'BAYOKO', 'NATHAN', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033228548', NULL, 1, NULL, '2015-03-19 07:12:26', '2015-03-22 23:36:49'),
(8, 'PAR0008', 'EGBEDEYI', 'SAMUEL', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023006777', NULL, 1, NULL, '2015-03-19 07:20:00', '2015-03-22 23:37:49'),
(9, 'PAR0009', 'HENRY-NKEKI', 'DAVID', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08123000064', NULL, 1, NULL, '2015-03-19 07:36:10', '2015-03-22 23:38:24'),
(10, 'PAR0010', 'IBILOLA', 'DAVID', 1, NULL, NULL, NULL, 'richardibilola@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033573649', NULL, 1, NULL, '2015-03-19 07:37:47', '2015-03-22 23:38:45'),
(11, 'PAR0011', 'NICK-IBITOYE ', 'OLANREWAJU', 1, NULL, NULL, NULL, 'nick.ibitoye@shell.com', NULL, NULL, NULL, NULL, NULL, '08035500298', NULL, 1, NULL, '2015-03-19 07:42:44', '2015-03-22 23:40:14'),
(12, 'PAR0012', 'NKUME-ANYIGOR ', 'VICTOR', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07033469369', NULL, 1, NULL, '2015-03-19 07:46:39', '2015-03-22 23:52:18'),
(13, 'PAR0013', 'OFOEGBUNAM', 'CHUKWUKA', 1, NULL, NULL, NULL, 'tmotrading@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08035755653', NULL, 1, NULL, '2015-03-19 07:51:38', '2015-03-22 23:54:21'),
(14, 'PAR0014', 'OGHOORE', 'JOSHUA', 1, NULL, NULL, NULL, 'oviemuno2002@yahoo.co.uk', NULL, NULL, NULL, NULL, NULL, '08033083745', NULL, 1, NULL, '2015-03-19 07:55:38', '2015-03-22 23:55:32'),
(15, 'PAR0015', 'OLAGUNJU', 'ADEYEMI', 1, NULL, NULL, NULL, 'homeinnlux@gmail.com', NULL, NULL, NULL, NULL, NULL, '08037697680', NULL, 1, NULL, '2015-03-19 07:57:44', '2015-03-22 23:56:25'),
(16, 'PAR0016', 'OLATUNBOSUN', 'OLANREWAJU JOSEPH', 1, NULL, NULL, NULL, 'loladeboy@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08028723456', NULL, 1, NULL, '2015-03-19 08:01:47', '2015-03-22 23:56:53'),
(17, 'PAR0017', 'YUSUF', 'AYODELE', 1, NULL, NULL, NULL, 'olabisiakinlabi@gmail.com', NULL, NULL, NULL, NULL, NULL, '08023401123', NULL, 1, NULL, '2015-03-19 08:03:41', '2015-03-23 00:11:06'),
(25, 'PAR0025', 'Ajayi', 'Oladapo', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08020593133', NULL, 13, NULL, '2015-03-24 10:17:45', '2015-03-24 09:17:45'),
(26, 'PAR0026', 'Opeyemi', 'Opeyemi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08189145603', NULL, 53, NULL, '2015-03-24 10:23:45', '2015-03-24 15:58:04'),
(29, 'PAR0029', 'Williams', 'Adegboyega', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08189145603', NULL, 53, NULL, '2015-03-24 10:49:42', '2015-03-24 09:49:42'),
(30, 'PAR0030', 'Adealu', 'Ifeoluwa', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023006122', NULL, 40, NULL, '2015-03-24 11:08:11', '2015-03-24 10:08:11'),
(32, 'PAR0032', 'ABADI', 'KEME', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08063753985', NULL, 30, NULL, '2015-03-24 11:21:47', '2015-03-24 10:21:47'),
(34, 'PAR0034', 'AMARA', 'EBIKABOERE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07038743024', NULL, 30, NULL, '2015-03-24 11:25:10', '2015-03-24 10:25:10'),
(35, 'PAR0035', 'ANIWETA-NEZIANYA', 'CHIAMAKA', 8, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08035900798', NULL, 30, NULL, '2015-03-24 11:26:48', '2015-03-24 10:26:48'),
(36, 'PAR0036', 'BAGOU', 'KENDRAH', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08031902363', NULL, 30, NULL, '2015-03-24 11:28:15', '2015-03-24 10:28:15'),
(37, 'PAR0037', 'ERIVWODE', 'OKEOGHENE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08066766565', NULL, 30, NULL, '2015-03-24 11:29:35', '2015-03-24 10:29:35'),
(38, 'PAR0038', 'GEORGEWILL', 'AYEBANENGIYEFA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037968795', NULL, 30, NULL, '2015-03-24 11:30:56', '2015-03-24 10:30:56'),
(39, 'PAR0039', 'ITSEUWA ', 'ROSEMARY', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033215262', NULL, 30, NULL, '2015-03-24 11:32:20', '2015-03-24 10:32:20'),
(40, 'PAR0040', 'JOB', 'VICTORIA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08135591296', NULL, 30, NULL, '2015-03-24 11:33:22', '2015-03-24 10:33:23'),
(41, 'PAR0041', 'KALAYOLO', 'HAPPINESS', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07062687122', NULL, 30, NULL, '2015-03-24 11:34:25', '2015-03-24 10:34:25'),
(42, 'PAR0042', 'MAZI', 'ONISOKIE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037899243', NULL, 30, NULL, '2015-03-24 11:36:03', '2015-03-24 10:36:03'),
(43, 'PAR0043', 'NATHANIEL', 'EVELYN', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08131346013', NULL, 30, NULL, '2015-03-24 11:37:04', '2015-03-24 10:37:04'),
(44, 'PAR0044', 'OBUBE', 'OYINKANSOLA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08067183793', NULL, 30, NULL, '2015-03-24 11:37:58', '2015-03-24 10:37:58'),
(45, 'PAR0045', 'OKE', 'OYINDAMOLA', 11, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08090906406', NULL, 30, NULL, '2015-03-24 11:38:54', '2015-03-24 10:38:54'),
(46, 'PAR0046', 'Otori', 'Jimoh', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023070934', NULL, 53, NULL, '2015-03-24 11:39:32', '2015-03-24 10:39:32'),
(47, 'PAR0047', 'OKOYE', 'CHISOM', 6, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023376269', NULL, 30, NULL, '2015-03-24 11:39:55', '2015-03-24 10:39:55'),
(48, 'PAR0048', 'Salau', 'Funke', 4, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023288942', NULL, 53, NULL, '2015-03-24 11:41:13', '2015-03-24 10:41:14'),
(49, 'PAR0049', 'TELIMOYE', 'IBEINMO', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07037722998', NULL, 30, NULL, '2015-03-24 11:41:32', '2015-03-24 10:41:32'),
(50, 'PAR0050', 'Adealu', 'Moruf', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023006122', NULL, 53, NULL, '2015-03-24 11:42:50', '2015-03-24 10:42:50'),
(51, 'PAR0051', 'WAIBITE', 'ENDURANCE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08168189756', NULL, 30, NULL, '2015-03-24 11:44:42', '2015-03-24 10:44:43'),
(52, 'PAR0052', 'Ojo', 'Oluwagbenga', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023318436', NULL, 53, NULL, '2015-03-24 11:45:33', '2015-03-24 10:45:33'),
(53, 'PAR0053', 'WILLIAMS', 'IBUKUN', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08038404056', NULL, 30, NULL, '2015-03-24 11:45:38', '2015-03-24 10:45:38'),
(54, 'PAR0054', 'Oloyede', 'Adekunle', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08024001476', NULL, 53, NULL, '2015-03-24 11:46:23', '2015-03-24 10:46:23'),
(55, 'PAR0055', 'Abioye', 'Oyinlade', 4, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023328277', NULL, 53, NULL, '2015-03-24 11:47:30', '2015-03-24 10:47:30'),
(56, 'PAR0056', 'Odesola', 'Jelili', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08061663367', NULL, 53, NULL, '2015-03-24 11:48:22', '2015-03-24 10:48:22'),
(57, 'PAR0057', 'ADEOSUN', 'Oladapo', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023125717', NULL, 52, NULL, '2015-03-24 12:17:24', '2015-03-24 11:17:24'),
(58, 'PAR0058', 'DADA', 'MUBARAK', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08026829359', NULL, 52, NULL, '2015-03-24 12:18:11', '2015-03-24 11:18:11'),
(59, 'PAR0059', 'ADEDOTUN', 'MICHEAL', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08085439241', NULL, 52, NULL, '2015-03-24 12:19:09', '2015-03-24 11:19:10'),
(60, 'PAR0060', 'AGUNBIADE', 'DEBORAH', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '09034109157', NULL, 52, NULL, '2015-03-24 12:21:48', '2015-03-24 11:21:48'),
(61, 'PAR0061', 'HAMZAT', 'Adekunle', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '080233359199', NULL, 52, NULL, '2015-03-24 12:22:32', '2015-03-24 11:22:33'),
(62, 'PAR0062', 'LALA', 'EMMANUEL', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08034015407', NULL, 52, NULL, '2015-03-24 12:23:09', '2015-03-24 11:23:10'),
(63, 'PAR0063', 'OKESINA', 'ADESOJI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08062883453', NULL, 52, NULL, '2015-03-24 12:23:48', '2015-03-24 11:23:48'),
(64, 'PAR0064', 'OJO', 'JOSEPH', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023176070', NULL, 52, NULL, '2015-03-24 12:24:29', '2015-03-24 11:24:30'),
(65, 'PAR0065', 'ADENIYI', 'IBAZEBO', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023193180', NULL, 52, NULL, '2015-03-24 12:40:25', '2015-03-24 11:40:25'),
(66, 'PAR0066', 'Azeez', 'Olufemi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08189268578', NULL, 14, NULL, '2015-03-24 12:49:56', '2015-03-24 11:49:57'),
(67, 'PAR0067', 'Bello', 'Tajudeen', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08092855295', NULL, 14, NULL, '2015-03-24 12:50:43', '2015-03-24 11:50:43'),
(68, 'PAR0068', 'Bello', 'Aderemi', 8, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08035103728', NULL, 14, NULL, '2015-03-24 12:51:49', '2015-03-24 11:51:49'),
(69, 'PAR0069', 'Bribena', 'Kelvin', 5, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08168800002', NULL, 14, NULL, '2015-03-24 12:52:39', '2015-03-24 11:52:39'),
(70, 'PAR0070', 'Folorunso', 'Isaac', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023120561', NULL, 14, NULL, '2015-03-24 12:55:00', '2015-03-24 11:55:00'),
(71, 'PAR0071', 'Ogundele', 'Amos', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08025015608', NULL, 14, NULL, '2015-03-24 12:55:31', '2015-03-24 11:55:31'),
(72, 'PAR0072', 'Olaoye', 'Oyekanmi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08057932322', NULL, 14, NULL, '2015-03-24 12:56:12', '2015-03-24 11:56:12'),
(73, 'PAR0073', 'Onyebuchi', 'Edwin', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033008296', NULL, 14, NULL, '2015-03-24 12:57:04', '2015-03-24 11:57:04'),
(74, 'PAR0074', 'Eze', 'Adaobi', 6, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033017899', NULL, 14, NULL, '2015-03-24 01:00:05', '2015-03-24 12:00:05'),
(75, 'PAR0075', 'Ibetei', 'Humphrey', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08062893168', NULL, 44, NULL, '2015-03-24 01:24:31', '2015-03-24 12:24:31'),
(76, 'PAR0076', 'Dede', 'Reginald', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08130786804', NULL, 44, NULL, '2015-03-24 01:25:40', '2015-03-24 12:25:40'),
(77, 'PAR0077', 'Abdou', 'Fatiou', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '22997224403', NULL, 44, NULL, '2015-03-24 01:28:24', '2015-03-24 12:28:24'),
(78, 'PAR0078', 'Obireke', 'Osoru', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08035185309', NULL, 44, NULL, '2015-03-24 01:29:12', '2015-03-24 12:29:12'),
(79, 'PAR0079', 'Umoru', 'Solomon', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08022030333', NULL, 44, NULL, '2015-03-24 01:30:08', '2015-03-24 12:30:09'),
(80, 'PAR0080', 'Nanakede', 'Smdoth', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08088657546', NULL, 44, NULL, '2015-03-24 01:32:02', '2015-03-24 12:32:03'),
(81, 'PAR0081', 'puragha', 'Bob', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08038921816', NULL, 44, NULL, '2015-03-24 01:33:19', '2015-03-24 12:33:19'),
(82, 'PAR0082', 'Soroh', 'Anthony', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08069760970', NULL, 44, NULL, '2015-03-24 01:34:06', '2015-03-24 12:34:07'),
(83, 'PAR0083', 'Maddocks', 'Christopher', 3, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08069097498', NULL, 44, NULL, '2015-03-24 01:34:59', '2015-03-24 12:34:59'),
(84, 'PAR0084', 'Isibor', 'Osahon', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07086455645', NULL, 44, NULL, '2015-03-24 01:35:43', '2015-03-24 12:35:43'),
(85, 'PAR0085', 'Zolo', 'Joshua', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032124113', NULL, 44, NULL, '2015-03-24 01:37:22', '2015-03-24 12:37:22'),
(86, 'PAR0086', 'Koroye ', 'Ebikabo', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037375525', NULL, 44, NULL, '2015-03-24 01:38:31', '2015-03-24 12:38:32'),
(87, 'PAR0087', 'Amakedi', 'Moneyman', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08053397636', NULL, 44, NULL, '2015-03-24 01:39:27', '2015-03-24 12:39:28'),
(88, 'PAR0088', 'Azugha', 'Sunday', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '080379911959', NULL, 44, NULL, '2015-03-24 01:40:04', '2015-03-24 12:40:04'),
(89, 'PAR0089', 'Abdullahi', 'Saadu', 1, NULL, NULL, NULL, 'abdusaadu@yahoo.co.uk', NULL, NULL, NULL, NULL, NULL, '08033026256', NULL, 65, NULL, '2015-03-24 01:40:06', '2015-03-24 12:40:06'),
(90, 'PAR0090', 'Inenemo-Usman', 'Abdul', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08035351939', NULL, 44, NULL, '2015-03-24 01:41:00', '2015-03-24 12:41:00'),
(91, 'PAR0091', 'adeyemi', 'J.A', 8, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08068678683', NULL, 65, NULL, '2015-03-24 01:41:01', '2015-03-24 12:41:02'),
(92, 'PAR0092', 'Adewole', 'Abdul', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023154167', NULL, 44, NULL, '2015-03-24 01:41:40', '2015-03-24 12:41:41'),
(94, 'PAR0094', 'kushimo', 'olakunle', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023434661', NULL, 60, NULL, '2015-03-24 01:43:36', '2015-03-24 12:43:36'),
(95, 'PAR0095', 'Sam-Micheal', 'Azibabhom', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07032420601', NULL, 44, NULL, '2015-03-24 01:43:46', '2015-03-24 12:43:47'),
(96, 'PAR0096', 'ajibode', 'adesoji', 1, NULL, NULL, NULL, 'cedarlinks2001@yahoo.com', NULL, NULL, NULL, NULL, NULL, '07034077523', NULL, 65, NULL, '2015-03-24 01:44:21', '2015-03-24 12:44:21'),
(97, 'PAR0097', 'Bagou', 'Ayibatare', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08063509486', NULL, 44, NULL, '2015-03-24 01:44:58', '2015-03-24 12:44:58'),
(98, 'PAR0098', 'faloye', 'omolade', 1, NULL, NULL, NULL, 'omoladefaloye@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08023193280', NULL, 65, NULL, '2015-03-24 01:45:33', '2015-03-24 12:45:33'),
(100, 'PAR0100', 'Isikpi', 'Nike', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08069760970', NULL, 44, NULL, '2015-03-24 01:47:14', '2015-03-24 12:47:14'),
(101, 'PAR0101', 'orhiunu', 'lina', 4, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '447930347074', NULL, 65, NULL, '2015-03-24 01:47:23', '2015-03-24 12:47:23'),
(102, 'PAR0102', 'imasuen', 'o.o', 1, NULL, NULL, NULL, 'femimasuen@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08022234476', NULL, 65, NULL, '2015-03-24 01:48:36', '2015-03-24 12:48:37'),
(103, 'PAR0103', 'Momoh', 'Muhsin', 5, NULL, NULL, NULL, 'amomoh@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033313424', NULL, 43, NULL, '2015-03-24 01:49:33', '2015-03-24 12:49:33'),
(104, 'PAR0104', 'ishola', 'yusuf', 1, NULL, NULL, NULL, 'yetty@gmail.com', NULL, NULL, NULL, NULL, NULL, '08034706971', NULL, 65, NULL, '2015-03-24 01:49:53', '2015-03-24 12:49:53'),
(105, 'PAR0105', 'Mbaegbu', 'Norbert', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037186709', NULL, 60, NULL, '2015-03-24 01:51:28', '2015-03-24 12:51:28'),
(106, 'PAR0106', 'madueke', 'Joseph', 1, NULL, NULL, NULL, 'madson1993@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033012374', NULL, 65, NULL, '2015-03-24 01:51:34', '2015-03-24 12:51:34'),
(107, 'PAR0107', 'odufuwa', 'ayodele', 1, NULL, NULL, NULL, 'odufuwdupe@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08055476213', NULL, 65, NULL, '2015-03-24 01:54:29', '2015-03-24 12:54:30'),
(108, 'PAR0108', 'olaniyan', 'p.a', 1, 'tt', '', '', 'akinolaniyanpms@yahoo.com', NULL, 'Hhgg', 147, 7, 140, '08033181314', '', 65, NULL, '2015-03-24 01:56:51', '2015-03-24 13:22:55'),
(109, 'PAR0109', 'olory', 'Matthew', 1, NULL, NULL, NULL, '0806666811', NULL, NULL, NULL, NULL, NULL, '08037865675', NULL, 65, NULL, '2015-03-24 02:00:01', '2015-03-24 13:00:01'),
(110, 'PAR0110', 'Tobiah', 'Emmanuel', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037950435', NULL, 43, NULL, '2015-03-24 02:00:32', '2015-03-24 13:00:32'),
(111, 'PAR0111', 'olory', 'Matthew', 1, NULL, NULL, NULL, 'matthewolory@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08066666811', NULL, 65, NULL, '2015-03-24 02:01:04', '2015-03-24 13:01:04'),
(112, 'PAR0112', 'oneh', 'Matthew', 1, NULL, NULL, NULL, 'm.oneh@interairnigeria.com', NULL, NULL, NULL, NULL, NULL, '08037865676', NULL, 65, NULL, '2015-03-24 02:06:06', '2015-03-24 13:06:06'),
(113, 'PAR0113', 'Oke', 'Isiaka', 11, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08090906406', NULL, 44, NULL, '2015-03-24 02:11:48', '2015-03-24 13:11:48'),
(114, 'PAR0114', 'onung', 'nkereuwem', 1, NULL, NULL, NULL, 'afimaonung@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08037135661', NULL, 65, NULL, '2015-03-24 02:12:04', '2015-03-24 13:12:04'),
(115, 'PAR0115', 'osadolor', 'Kingsley', 1, NULL, NULL, NULL, 'osakingosa@hotmail.com', NULL, NULL, NULL, NULL, NULL, '08033042837', NULL, 65, NULL, '2015-03-24 02:15:02', '2015-03-24 13:15:02'),
(116, 'PAR0116', 'ATABULE', 'FAITH', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08055024772', NULL, 60, NULL, '2015-03-24 02:18:25', '2015-03-24 13:18:26'),
(117, 'PAR0117', 'KUSHIMOH', 'OLAMIDE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08054881234', NULL, 60, NULL, '2015-03-24 02:19:05', '2015-03-24 13:19:05'),
(119, 'PAR0119', 'OGUNDIMU', 'MOTUNRAYO', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08050442115', NULL, 60, NULL, '2015-03-24 02:21:29', '2015-03-24 13:21:29'),
(120, 'PAR0120', 'BUHARI-ABDULLAHI', 'HAUWA', 11, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033024367', NULL, 60, NULL, '2015-03-24 02:22:41', '2015-03-24 13:22:41'),
(121, 'PAR0121', 'Faloye', 'Ayomide', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033040696', NULL, 43, NULL, '2015-03-24 02:22:59', '2015-03-24 13:22:59'),
(122, 'PAR0122', 'LAWAL', 'ENIOLA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033370213', NULL, 60, NULL, '2015-03-24 02:24:32', '2015-03-24 13:24:32'),
(123, 'PAR0123', 'Asubiaro', 'Tomisin', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08030839881', NULL, 13, NULL, '2015-03-24 02:24:51', '2015-03-24 13:24:51'),
(124, 'PAR0124', 'ibeke', 'okey', 1, NULL, NULL, NULL, 'bekey4all@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033040009', NULL, 65, NULL, '2015-03-24 02:25:03', '2015-03-24 13:25:03'),
(125, 'PAR0125', 'ITSEUWA', 'EMILY', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033215262', NULL, 60, NULL, '2015-03-24 02:26:10', '2015-03-24 13:26:10'),
(126, 'PAR0126', 'OSHOBU', 'OLUWAFUNMILAYO', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023039969', NULL, 60, NULL, '2015-03-24 02:27:47', '2015-03-24 13:27:47'),
(127, 'PAR0127', 'SANNI', 'OLUWASEUN', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023187676', NULL, 60, NULL, '2015-03-24 02:28:52', '2015-03-24 13:28:53'),
(128, 'PAR0128', 'ONYEMAECHI', 'JENNIFER', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033088494', NULL, 60, NULL, '2015-03-24 02:29:56', '2015-03-24 13:29:56'),
(129, 'PAR0129', 'ERIVWODE ', 'RUKEVWE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08066766565', NULL, 60, NULL, '2015-03-24 02:31:00', '2015-03-24 13:31:01'),
(130, 'PAR0130', 'LAWAL', 'HABEEBAT', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033379127', NULL, 60, NULL, '2015-03-24 02:32:03', '2015-03-24 13:32:03'),
(131, 'PAR0131', 'POPOOLA', 'IBUKUN', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07085810372', NULL, 60, NULL, '2015-03-24 02:32:59', '2015-03-24 13:32:59'),
(132, 'PAR0132', 'NOIKI', 'OLUWATOMIWA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023092160', NULL, 60, NULL, '2015-03-24 02:33:52', '2015-03-24 13:33:53'),
(133, 'PAR0133', 'EZEJELUE', 'SOMKENE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037278502', NULL, 60, NULL, '2015-03-24 02:34:55', '2015-03-24 13:34:55'),
(134, 'PAR0134', 'Faluade', 'Kayode', 1, NULL, NULL, NULL, 'Kayodefaluade@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08023361524', NULL, 50, NULL, '2015-03-24 02:48:18', '2015-03-24 13:48:18'),
(135, 'PAR0135', 'Hamman-Obel', 'Ogheneyoma', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08026806660', NULL, 43, NULL, '2015-03-24 02:48:23', '2015-03-24 13:48:24'),
(136, 'PAR0136', 'Akintola', 'Ibrahim', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033049351', NULL, 50, NULL, '2015-03-24 02:50:38', '2015-03-24 13:50:38'),
(137, 'PAR0137', 'Hassan', 'Adetunji', 1, NULL, NULL, NULL, 'Hassankhadijan@gmail.com', NULL, NULL, NULL, NULL, NULL, '08055463880', NULL, 50, NULL, '2015-03-24 02:52:09', '2015-03-24 13:52:09'),
(138, 'PAR0138', 'Okesina', 'Victor', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08062883453', NULL, 50, NULL, '2015-03-24 02:53:42', '2015-03-24 13:53:42'),
(139, 'PAR0139', 'Adeniyi', 'Adeyinka', 1, NULL, NULL, NULL, 'ontop.affairs@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08029727676', NULL, 50, NULL, '2015-03-24 02:54:59', '2015-03-24 13:55:00'),
(141, 'PAR0141', 'Adesina', 'Adekunle', 1, NULL, NULL, NULL, 'Adekunle.adesina@gmail.com', NULL, NULL, NULL, NULL, NULL, '08034722758', NULL, 50, NULL, '2015-03-24 02:59:11', '2015-03-24 13:59:11'),
(142, 'PAR0142', 'Agunbiade', 'Olukayode', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07031193987', NULL, 50, NULL, '2015-03-24 03:03:38', '2015-03-24 14:03:38'),
(143, 'PAR0143', 'Chinda', 'Hope', 1, NULL, NULL, NULL, 'Adekokun2@hotmail.com', NULL, NULL, NULL, NULL, NULL, '08023335056', NULL, 50, NULL, '2015-03-24 03:04:50', '2015-03-24 14:04:50'),
(144, 'PAR0144', 'Samson', 'Olufemi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08168442659', NULL, 50, NULL, '2015-03-24 03:06:43', '2015-03-24 14:06:43'),
(145, 'PAR0145', 'ABDOU', 'AMOUDATH', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '22997222403', NULL, 60, NULL, '2015-03-24 03:08:15', '2015-03-24 18:43:11'),
(146, 'PAR0146', 'BAKRE', 'BABAJIDE', 1, NULL, NULL, NULL, 'jidebakre@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033076087', NULL, 13, NULL, '2015-03-24 03:13:57', '2015-03-25 15:39:27'),
(147, 'PAR0147', 'chiejile', 'Williams', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08051245920', NULL, 13, NULL, '2015-03-24 03:14:55', '2015-03-24 14:14:55'),
(148, 'PAR0148', 'Lawal', 'Sunkanmi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033370213', NULL, 13, NULL, '2015-03-24 03:15:30', '2015-03-24 14:15:30'),
(149, 'PAR0149', 'Nwogu', 'Victor', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '0803397834', NULL, 13, NULL, '2015-03-24 03:16:18', '2015-03-24 14:16:19'),
(150, 'PAR0150', 'Okeke ', 'Chigozie', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032463769', NULL, 13, NULL, '2015-03-24 03:16:55', '2015-03-24 14:16:56'),
(151, 'PAR0151', 'Ogunbanjo', 'Timilehin', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033058040', NULL, 13, NULL, '2015-03-24 03:17:35', '2015-03-24 14:17:36'),
(152, 'PAR0152', 'Onwuchelu ', 'Christian', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '22505052049', NULL, 13, NULL, '2015-03-24 03:18:41', '2015-03-24 14:18:42'),
(153, 'PAR0153', 'Soyebi', 'Oluwaseun', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08060854491', NULL, 13, NULL, '2015-03-24 03:19:19', '2015-03-24 14:19:20'),
(154, 'PAR0154', 'Uduji-Emenike', 'Chibueze', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033283134', NULL, 13, NULL, '2015-03-24 03:20:06', '2015-03-24 14:20:06'),
(155, 'PAR0155', 'Olatunbosun', 'Olaoluwa', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08028723456', NULL, 13, NULL, '2015-03-24 03:21:08', '2015-03-24 14:21:08'),
(156, 'PAR0156', 'Ikpi-Iyam', 'Felix', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033131070', NULL, 13, NULL, '2015-03-24 03:21:53', '2015-03-24 14:21:53'),
(158, 'PAR0158', 'KAZEEM', 'OLAWALE', 11, NULL, NULL, NULL, 'Kazwal2@yahoo.com', NULL, NULL, NULL, NULL, NULL, '018907218', NULL, 60, NULL, '2015-03-24 03:38:18', '2015-03-24 14:38:19'),
(159, 'PAR0159', 'UGOCHUKWU', 'CHRISTINA', 4, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08034027185', NULL, 60, NULL, '2015-03-24 03:44:20', '2015-03-24 14:44:20'),
(160, 'PAR0160', 'OJUDU', 'BABAFEMI ', 1, NULL, NULL, NULL, 'ojudubabafemi@gmail.com', NULL, NULL, NULL, NULL, NULL, '08023033594', NULL, 60, NULL, '2015-03-24 03:52:35', '2015-03-24 14:52:35'),
(161, 'PAR0161', 'Afolabi', 'wuraola', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07062845703', NULL, 23, NULL, '2015-03-24 03:55:54', '2015-03-24 14:55:55'),
(162, 'PAR0162', 'Angel', 'EMMANUEL', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032185524', NULL, 23, NULL, '2015-03-24 03:56:54', '2015-03-24 14:56:54'),
(163, 'PAR0163', 'Ikpi-Iyam', 'Irene', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033131070', NULL, 23, NULL, '2015-03-24 03:58:14', '2015-03-24 14:58:14'),
(164, 'PAR0164', 'Johnson', 'Precious', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08026621330', NULL, 23, NULL, '2015-03-24 03:59:31', '2015-03-24 14:59:31'),
(165, 'PAR0165', 'Okey-Ezealah', 'Viola', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08055288380', NULL, 23, NULL, '2015-03-24 04:02:07', '2015-03-24 15:02:07'),
(166, 'PAR0166', 'Oshobu', 'Yemisi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023164370', NULL, 23, NULL, '2015-03-24 04:03:30', '2015-03-24 15:03:31'),
(168, 'PAR0168', 'Sobowale', 'Anike', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037235348', NULL, 23, NULL, '2015-03-24 04:05:42', '2015-03-24 15:05:42'),
(169, 'PAR0169', 'Yahaya', 'Mariam', 11, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033045008', NULL, 23, NULL, '2015-03-24 04:06:59', '2015-03-24 15:06:59'),
(170, 'PAR0170', 'DANDEKAR', 'RAJEEV', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08024780331', NULL, 62, NULL, '2015-03-24 04:09:02', '2015-03-24 15:09:02'),
(171, 'PAR0171', 'ONONAEKE', 'KENNEDY', 5, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08056316263', NULL, 62, NULL, '2015-03-24 04:10:28', '2015-03-24 15:10:28'),
(172, 'PAR0172', 'ANAGBE', 'PETER PAUL', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08062100389', NULL, 62, NULL, '2015-03-24 04:12:03', '2015-03-24 15:12:04'),
(173, 'PAR0173', 'ALAYANDE', 'OLALEKAN', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08036158009', NULL, 62, NULL, '2015-03-24 04:13:06', '2015-03-24 15:13:06'),
(174, 'PAR0174', 'OYENIRAN', 'MUFTAU', 11, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08024401482', NULL, 62, NULL, '2015-03-24 04:13:52', '2015-03-24 15:13:52'),
(178, 'PAR0178', 'Olukokun', 'Adediran', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023335056', NULL, 50, NULL, '2015-03-24 04:24:32', '2015-03-24 15:24:32'),
(179, 'PAR0179', 'AKINTELU', 'ADEBAYO', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07034154821', NULL, 62, NULL, '2015-03-24 04:27:11', '2015-03-24 15:27:11'),
(180, 'PAR0180', 'LAWRENCE', 'ADEPOJU', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023031469', NULL, 62, NULL, '2015-03-24 04:35:02', '2015-03-24 15:35:02'),
(181, 'PAR0181', 'ABIOLA', 'HAFEEZ', 1, NULL, NULL, NULL, 'habiola@elektrint.com', NULL, NULL, NULL, NULL, NULL, '08033065549', NULL, 16, NULL, '2015-03-24 04:35:06', '2015-03-24 15:35:07'),
(182, 'PAR0182', 'OLADAPO', 'ADEOSUN', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033463008', NULL, 62, NULL, '2015-03-24 04:36:05', '2015-03-24 15:36:06'),
(183, 'PAR0183', 'ADENIYI', 'ABDULSALAM ', 1, NULL, NULL, NULL, 'wallayadeniyi@yahoo.co.uk', NULL, NULL, NULL, NULL, NULL, '08033142881', NULL, 16, NULL, '2015-03-24 04:37:02', '2015-03-24 15:37:03'),
(184, 'PAR0184', 'UBANDOMA', 'BELLO', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032260898', NULL, 62, NULL, '2015-03-24 04:37:47', '2015-03-24 15:37:47'),
(185, 'PAR0185', 'AJIBOLA', 'ISLAM', 1, NULL, NULL, NULL, 'tempuston@yahoo.com', NULL, NULL, NULL, NULL, NULL, '07061376488', NULL, 16, NULL, '2015-03-24 04:38:16', '2015-03-24 15:38:16'),
(186, 'PAR0186', 'BAKARE', 'OLUDAYO', 1, NULL, NULL, NULL, 'Rafiu.Bakare@zenithbank.com', NULL, NULL, NULL, NULL, NULL, '08033087642', NULL, 16, NULL, '2015-03-24 04:39:18', '2015-03-24 15:39:18'),
(188, 'PAR0188', 'BELLO ', 'AYOTUNDE', 1, NULL, NULL, NULL, 'bello_topza@yahoo.co.uk', NULL, NULL, NULL, NULL, NULL, '08055832217', NULL, 16, NULL, '2015-03-24 04:40:26', '2015-03-24 15:40:26'),
(189, 'PAR0189', 'EMMANUEL', 'OBINNA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032185524', NULL, 16, NULL, '2015-03-24 04:41:32', '2015-03-24 15:41:32'),
(190, 'PAR0190', 'FOLORUNSO', 'IYIOLA', 1, NULL, NULL, NULL, 'isaac.folorunso@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08023120561', NULL, 16, NULL, '2015-03-24 04:43:05', '2015-03-24 15:43:05'),
(191, 'PAR0191', 'IDOWU', 'OLUWABUKUNMI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033034118', NULL, 16, NULL, '2015-03-24 04:44:17', '2015-03-24 15:44:17'),
(192, 'PAR0192', 'NIKORO', 'OMAGBITSE', 1, NULL, NULL, NULL, 'tonynikoro@yahoo.co.uk', NULL, NULL, NULL, NULL, NULL, '08051095262', NULL, 16, NULL, '2015-03-24 04:45:18', '2015-03-24 15:45:19'),
(193, 'PAR0193', 'FAYOMI', 'I', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08035070732', NULL, 62, NULL, '2015-03-24 04:45:48', '2015-03-24 15:45:49'),
(194, 'PAR0194', 'OBRIBAI', 'SAMSON', 1, NULL, NULL, NULL, 'yeyeone@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08038266225', NULL, 16, NULL, '2015-03-24 04:46:23', '2015-03-24 15:46:23'),
(195, 'PAR0195', 'ELENDU', 'CHURCHIL', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08034740241', NULL, 62, NULL, '2015-03-24 04:46:53', '2015-03-24 15:46:53'),
(196, 'PAR0196', 'OGUNDIMU ', 'MOBOLUWADURO', 1, NULL, NULL, NULL, 'sina_ogun@yahoo.co.uk', NULL, NULL, NULL, NULL, NULL, '08037224353', NULL, 16, NULL, '2015-03-24 04:47:24', '2015-03-24 15:47:24'),
(198, 'PAR0198', 'OGUNEKO', 'AYOOLA', 1, NULL, NULL, NULL, 'oguneko.o@acn.aero', NULL, NULL, NULL, NULL, NULL, '08034061274', NULL, 16, NULL, '2015-03-24 04:48:52', '2015-03-24 15:48:52'),
(199, 'PAR0199', 'OKOYE ', 'PAUL', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032235812', NULL, 16, NULL, '2015-03-24 04:49:29', '2015-03-24 15:49:29'),
(200, 'PAR0200', 'OKPARA', 'NATHANIEL', 1, NULL, NULL, NULL, 'daniel.okpara@qualitymarineng.com', NULL, NULL, NULL, NULL, NULL, '08034345521', NULL, 16, NULL, '2015-03-24 04:50:29', '2015-03-24 15:50:29'),
(201, 'PAR0201', 'SOWOLE', 'AYOTOMI ', 1, NULL, NULL, NULL, 'sowoles@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08035942511', NULL, 16, NULL, '2015-03-24 04:51:28', '2015-03-24 15:51:28'),
(204, 'PAR0204', 'SOGE', 'ABAYOMI', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08024700738', NULL, 62, NULL, '2015-03-24 06:55:11', '2015-03-24 17:55:11'),
(205, 'PAR0205', 'RAJI', 'HABEEB', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08026301862', NULL, 62, NULL, '2015-03-24 06:58:45', '2015-03-24 17:58:45'),
(206, 'PAR0206', 'OSINAIKE', 'OLANREWAJU', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033212239', NULL, 62, NULL, '2015-03-24 07:04:54', '2015-03-24 18:04:54'),
(207, 'PAR0207', 'AMZAT', 'YAYA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07074969994', NULL, 62, NULL, '2015-03-24 07:08:01', '2015-03-24 18:08:01'),
(208, 'PAR0208', 'Soge', 'Olumuyiwa', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08036661699', NULL, 40, NULL, '2015-03-25 08:12:08', '2015-03-25 07:12:08'),
(209, 'PAR0209', 'Shadouh', 'Hani', 8, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08039567889', NULL, 40, NULL, '2015-03-25 08:15:40', '2015-03-25 07:15:40'),
(210, 'PAR0210', 'Ibazebo', 'Adeniyi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08094649847', NULL, 40, NULL, '2015-03-25 08:17:47', '2015-03-25 07:17:47'),
(211, 'PAR0211', 'Ajisebutu', 'Olusayo', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08052155846', NULL, 40, NULL, '2015-03-25 08:20:41', '2015-03-25 07:20:41'),
(212, 'PAR0212', 'Oshunlola', 'Yisa', 11, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033436172', NULL, 40, NULL, '2015-03-25 08:21:29', '2015-03-25 07:21:29'),
(213, 'PAR0213', 'Olaore', 'Oludare', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08055257545', NULL, 40, NULL, '2015-03-25 08:22:43', '2015-03-25 07:22:43'),
(214, 'PAR0214', 'Olasedidun', 'Tunde', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08065058550', NULL, 40, NULL, '2015-03-25 08:26:32', '2015-03-25 07:26:32'),
(215, 'PAR0215', 'Adepoju', 'Lawrence', 7, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023031469', NULL, 40, NULL, '2015-03-25 08:28:22', '2015-03-25 07:28:22'),
(216, 'PAR0216', 'Onwuchelu', 'Emeka', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '05052049', NULL, 43, NULL, '2015-03-25 09:13:15', '2015-03-25 08:13:15'),
(217, 'PAR0217', 'Ishola', 'Bolaji', 1, NULL, NULL, NULL, 'adeoluwafaniyi@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08023409352', NULL, 43, NULL, '2015-03-25 09:19:24', '2015-03-25 08:19:24'),
(218, 'PAR0218', 'Akpama', 'Paul', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07062849533', NULL, 43, NULL, '2015-03-25 09:23:02', '2015-03-25 08:23:02'),
(219, 'PAR0219', 'Wikimor', 'John', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08052462012', NULL, 43, NULL, '2015-03-25 09:25:44', '2015-03-25 08:25:44'),
(220, 'PAR0220', 'Ziworitin', 'Ebikabo-Owei', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07036603754', NULL, 43, NULL, '2015-03-25 09:30:26', '2015-03-25 08:30:27'),
(221, 'PAR0221', 'Olumese', 'Anthony', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07098702770', NULL, 38, NULL, '2015-03-25 09:31:19', '2015-03-25 08:31:19'),
(222, 'PAR0222', 'Markbere', 'Abraham', 2, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07030952769', NULL, 43, NULL, '2015-03-25 09:33:05', '2015-03-25 08:33:05'),
(223, 'PAR0223', 'Okunbor', 'Ifeanyi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08034029238', NULL, 38, NULL, '2015-03-25 09:34:37', '2015-03-25 08:34:37'),
(224, 'PAR0224', 'Osinbanjo', 'Oluwafemi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033223660', NULL, 38, NULL, '2015-03-25 09:35:20', '2015-03-25 08:35:21'),
(225, 'PAR0225', 'Awolaja', 'Adekunle', 1, NULL, NULL, NULL, 'kunlaj2002@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08053021329', NULL, 38, NULL, '2015-03-25 09:35:58', '2015-03-25 14:05:56'),
(226, 'PAR0226', 'Abdou', 'Fatou', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '+22990927584', NULL, 38, NULL, '2015-03-25 09:37:01', '2015-03-25 08:37:01'),
(227, 'PAR0227', 'Emmanuel', 'Offodile', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032185524', NULL, 38, NULL, '2015-03-25 09:38:02', '2015-03-25 08:38:02'),
(228, 'PAR0228', 'Ohadike', 'Michael', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023003470', NULL, 38, NULL, '2015-03-25 09:38:40', '2015-03-25 08:38:40'),
(229, 'PAR0229', 'Owhonda', 'Okechukwu', 7, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023119504', NULL, 38, NULL, '2015-03-25 09:39:32', '2015-03-25 08:39:32'),
(230, 'PAR0230', 'Eldine', 'Layefa', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08037794556', NULL, 43, NULL, '2015-03-25 09:41:57', '2015-03-25 08:41:57'),
(231, 'PAR0231', 'Simolings', 'Simolings', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08024685146', NULL, 43, NULL, '2015-03-25 09:45:43', '2015-03-25 08:45:43'),
(232, 'PAR0232', 'Anagbe', 'Peter', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08062100829', NULL, 54, NULL, '2015-03-25 09:51:13', '2015-03-25 08:51:13'),
(233, 'PAR0233', 'Akinola', 'Afolabi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '+447404659884', NULL, 54, NULL, '2015-03-25 09:51:59', '2015-03-25 08:51:59'),
(234, 'PAR0234', 'Shadrack', 'Amos', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08057340467', NULL, 43, NULL, '2015-03-25 09:53:48', '2015-03-25 08:53:48'),
(235, 'PAR0235', 'Gbadebo', 'Adebisi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07062786208', NULL, 54, NULL, '2015-03-25 09:54:00', '2015-03-25 08:54:00'),
(236, 'PAR0236', 'Ogundeyi', 'Najeem', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08032380610', NULL, 54, NULL, '2015-03-25 09:55:34', '2015-03-25 08:55:35'),
(237, 'PAR0237', 'Ogunbona', 'Ismael', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033244810', NULL, 54, NULL, '2015-03-25 09:57:57', '2015-03-25 08:57:58'),
(238, 'PAR0238', 'Olukokun', 'Adeniran', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023335056', NULL, 54, NULL, '2015-03-25 10:04:05', '2015-03-25 09:04:05'),
(239, 'PAR0239', 'Ojo', 'Oluwagbenga', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033436172', NULL, 54, NULL, '2015-03-25 10:04:48', '2015-03-25 09:04:48'),
(240, 'PAR0240', 'Raji', 'Habeeb', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023335273', NULL, 54, NULL, '2015-03-25 10:05:33', '2015-03-25 09:05:33'),
(241, 'PAR0241', 'Adeola', 'Rotimi', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08055154675', NULL, 54, NULL, '2015-03-25 10:06:21', '2015-03-25 09:06:21'),
(242, 'PAR0242', 'Oyedeji', 'James', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08026819964', NULL, 54, NULL, '2015-03-25 10:07:28', '2015-03-25 09:07:28'),
(243, 'PAR0243', 'Promise', 'Joel', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08068050905', NULL, 43, NULL, '2015-03-25 10:08:33', '2015-03-25 09:08:34'),
(244, 'PAR0244', 'Agadah', 'Ebiye', 1, NULL, NULL, NULL, 'chairman.bssb.gov.com', NULL, NULL, NULL, NULL, NULL, '07062522236', NULL, 43, NULL, '2015-03-25 10:35:52', '2015-03-25 09:35:52'),
(246, 'PAR0246', 'Jesumienpreder', 'Ayere', 1, NULL, NULL, NULL, 'chairman.bssb@gmail.com', NULL, NULL, NULL, NULL, NULL, '07062522236', NULL, 43, NULL, '2015-03-25 10:41:43', '2015-03-25 09:41:44'),
(247, 'PAR0247', 'DANIEL', 'Emmanuel', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08152662481', NULL, 43, NULL, '2015-03-25 11:35:25', '2015-03-25 10:35:25'),
(248, 'PAR0248', 'Akunwa', 'Glory', 1, 'Property Developer', 'Glomykes Property Development Co. Ltd.', '', 'glomyke@yahoo.com', NULL, 'D46, Royal Gardens Estate, Ajah - Lekki, Lagos.', 188, 9, 140, '08023020139', '08025191010', 42, NULL, '2015-03-25 12:44:02', '2015-03-25 19:21:50'),
(249, 'PAR0249', 'Anokwuru', 'Obioma', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023121077', NULL, 42, NULL, '2015-03-25 12:46:14', '2015-03-25 11:46:14'),
(251, 'PAR0251', 'Bello', 'Garba', 1, NULL, NULL, NULL, 'gbkankarofi@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08023240911', NULL, 42, NULL, '2015-03-25 12:50:12', '2015-03-25 11:50:12'),
(252, 'PAR0252', 'DADINSON-OGBOGBO ', 'David', 1, NULL, NULL, NULL, 'tone_ventures@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08032002657', NULL, 42, NULL, '2015-03-25 12:51:49', '2015-03-25 11:51:50'),
(253, 'PAR0253', 'Bayelsa', 'Guardian', 1, NULL, NULL, NULL, 'oyinbunugha@gmail.com', NULL, NULL, NULL, NULL, NULL, '07062522236', NULL, 46, NULL, '2015-03-25 01:27:30', '2015-03-25 12:27:30'),
(254, 'PAR0254', 'NWOKEKE', 'FAVOUR', 1, NULL, NULL, NULL, 'nwokekebasil@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08032002294', NULL, 46, NULL, '2015-03-25 01:31:40', '2015-03-25 12:31:40'),
(256, 'PAR0256', 'DADINSON-OGBOGBO ', 'David', 1, NULL, NULL, NULL, 'tone_ventures@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08032002657', NULL, 42, NULL, '2015-03-25 02:01:23', '2015-03-25 13:01:23'),
(257, 'PAR0257', 'DAPPAH ', 'Owabomate', 1, NULL, NULL, NULL, 'dappaizrael@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08024379053', NULL, 42, NULL, '2015-03-25 02:05:07', '2015-03-25 13:05:07'),
(258, 'PAR0258', 'EZIMOHA ', 'EBUBECHI', 1, NULL, NULL, NULL, 'okechukwu.ezimoha@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033314669', NULL, 42, NULL, '2015-03-25 02:09:37', '2015-03-25 13:09:37'),
(259, 'PAR0259', 'NNOROM', 'MIRACLE', 1, NULL, NULL, NULL, 'emmanuel.nnorom@ubagroup.com', NULL, NULL, NULL, NULL, NULL, '08033034944', NULL, 42, NULL, '2015-03-25 02:18:48', '2015-03-25 13:18:48'),
(260, 'PAR0260', 'OGBECHIE', 'CHIDIEBUBE', 1, NULL, NULL, NULL, 'nyem0430@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033353232', NULL, 42, NULL, '2015-03-25 02:20:16', '2015-03-25 13:20:17'),
(261, 'PAR0261', 'OKEREAFOR', 'EBUBE', 1, NULL, NULL, NULL, 'goddyuoconcept@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08034040316', NULL, 42, NULL, '2015-03-25 02:23:04', '2015-03-25 13:23:04'),
(262, 'PAR0262', 'OLANIYONU', 'OLADIPO', 1, NULL, NULL, NULL, 'yusuphola@yahoo.co.uk', NULL, NULL, NULL, NULL, NULL, '08055001965', NULL, 42, NULL, '2015-03-25 02:25:08', '2015-03-25 13:25:08'),
(263, 'PAR0263', 'UNAH', 'RINCHA', 1, NULL, NULL, NULL, 'nwaunah@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08023232152', NULL, 42, NULL, '2015-03-25 02:33:42', '2015-03-25 13:33:42'),
(264, 'PAR0264', 'IGWE', 'CHUKWURAH', 4, NULL, NULL, NULL, 'kemfe@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08033005452', NULL, 32, NULL, '2015-03-25 04:23:23', '2015-03-25 15:23:23'),
(265, 'PAR0265', 'OBIDIEGWU', 'DANIEL', 1, NULL, NULL, NULL, 'daobidiegwu@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08034788780', NULL, 32, NULL, '2015-03-25 04:24:43', '2015-03-25 15:24:43'),
(266, 'PAR0266', 'AGBAWHE', 'MATTHEW', 8, NULL, NULL, NULL, 'matty2001@yahoo.com', NULL, NULL, NULL, NULL, NULL, '08023252981', NULL, 32, NULL, '2015-03-25 04:27:08', '2015-03-25 15:27:08'),
(267, 'PAR0267', 'ASAKITIPI', 'ALEX', 1, NULL, NULL, NULL, 'alexasak@yahoo.com', NULL, NULL, NULL, NULL, NULL, '27738500581', NULL, 32, NULL, '2015-03-25 04:29:25', '2015-03-25 15:29:25'),
(268, 'PAR0268', 'ODESANYA', 'KOREDE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08023014818', NULL, 59, NULL, '2015-03-25 04:47:56', '2015-03-25 15:47:57'),
(269, 'PAR0269', 'OSHINAIKE', 'TEMILOLUWA', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '08033212239', NULL, 59, NULL, '2015-03-25 04:54:09', '2015-03-25 15:54:09'),
(270, 'PAR0270', 'TOOGUN', 'YEWANDE', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07038166337', NULL, 59, NULL, '2015-03-25 04:55:22', '2015-03-25 15:55:23'),
(271, 'PAR0271', 'ENI', 'JEREMIAH', 1, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '07056058605', NULL, 59, NULL, '2015-03-25 04:57:12', '2015-03-25 15:57:13'),
(272, 'PAR0272', 'OPARA', 'HOPE', 1, NULL, NULL, NULL, 'toykachy@yahoo.com', NULL, NULL, NULL, NULL, NULL, '07029198727', NULL, 32, NULL, '2015-03-25 05:07:48', '2015-03-25 16:07:49'),
(273, 'PAR0273', 'NICHOLAS', 'Daaiyefumasu', 1, NULL, NULL, NULL, 'chairman.bssb@gmail.com', NULL, NULL, NULL, NULL, NULL, '07062522236', NULL, 43, NULL, '2015-03-26 12:22:49', '2015-03-26 11:22:49');

-- --------------------------------------------------------

--
-- Table structure for table `sponsorship_types`
--

DROP TABLE IF EXISTS `sponsorship_types`;
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

DROP TABLE IF EXISTS `spouse_details`;
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

DROP TABLE IF EXISTS `states`;
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

DROP TABLE IF EXISTS `status`;
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
DROP VIEW IF EXISTS `student_feesqueryviews`;
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
DROP VIEW IF EXISTS `student_feesviews`;
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

DROP TABLE IF EXISTS `student_status`;
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

DROP TABLE IF EXISTS `students`;
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

DROP TABLE IF EXISTS `students_classes`;
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
DROP VIEW IF EXISTS `students_classlevelviews`;
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
DROP VIEW IF EXISTS `students_paymentviews`;
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
DROP VIEW IF EXISTS `students_subjectsviews`;
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

DROP TABLE IF EXISTS `subject_classlevels`;
CREATE TABLE IF NOT EXISTS `subject_classlevels` (
`subject_classlevel_id` int(11) NOT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `classlevel_id` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `academic_term_id` int(11) DEFAULT NULL,
  `examstatus_id` int(11) DEFAULT '2'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=29 ;

--
-- Dumping data for table `subject_classlevels`
--

INSERT INTO `subject_classlevels` (`subject_classlevel_id`, `subject_id`, `classlevel_id`, `class_id`, `academic_term_id`, `examstatus_id`) VALUES
(1, 1, 1, 1, 1, 2),
(5, 1, 1, 2, 1, 2),
(9, 1, 1, 4, 1, 2),
(13, 1, 1, 5, 1, 2),
(19, 1, 4, 17, 1, 2),
(23, 1, 4, 19, 1, 2),
(27, 1, 4, 20, 1, 2),
(2, 2, 1, 1, 1, 2),
(6, 2, 1, 2, 1, 2),
(10, 2, 1, 4, 1, 2),
(14, 2, 1, 5, 1, 2),
(20, 2, 4, 17, 1, 2),
(24, 2, 4, 19, 1, 2),
(28, 2, 4, 20, 1, 2),
(18, 9, 4, 17, 1, 2),
(22, 9, 4, 19, 1, 2),
(26, 9, 4, 20, 1, 2),
(4, 16, 1, 1, 1, 2),
(8, 16, 1, 2, 1, 2),
(12, 16, 1, 4, 1, 2),
(16, 16, 1, 5, 1, 2),
(3, 17, 1, 1, 1, 2),
(7, 17, 1, 2, 1, 2),
(11, 17, 1, 4, 1, 2),
(15, 17, 1, 5, 1, 2),
(17, 23, 4, 17, 1, 2),
(21, 23, 4, 19, 1, 2),
(25, 23, 4, 20, 1, 2);

-- --------------------------------------------------------

--
-- Stand-in structure for view `subject_classlevelviews`
--
DROP VIEW IF EXISTS `subject_classlevelviews`;
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

DROP TABLE IF EXISTS `subject_groups`;
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

DROP TABLE IF EXISTS `subject_students_registers`;
CREATE TABLE IF NOT EXISTS `subject_students_registers` (
  `student_id` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `subject_classlevel_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `subject_students_registers`
--

INSERT INTO `subject_students_registers` (`student_id`, `class_id`, `subject_classlevel_id`) VALUES
(1, 2, 5),
(1, 2, 6),
(1, 2, 7),
(1, 2, 8),
(2, 2, 5),
(2, 2, 6),
(2, 2, 7),
(2, 2, 8),
(3, 2, 5),
(3, 2, 6),
(3, 2, 7),
(3, 2, 8),
(4, 2, 5),
(4, 2, 6),
(4, 2, 7),
(4, 2, 8),
(5, 2, 5),
(5, 2, 6),
(5, 2, 7),
(5, 2, 8),
(6, 2, 5),
(6, 2, 6),
(6, 2, 7),
(6, 2, 8),
(7, 2, 5),
(7, 2, 6),
(7, 2, 7),
(7, 2, 8),
(10, 2, 5),
(10, 2, 6),
(10, 2, 7),
(10, 2, 8),
(11, 2, 5),
(11, 2, 6),
(11, 2, 7),
(11, 2, 8),
(12, 2, 5),
(12, 2, 6),
(12, 2, 7),
(12, 2, 8),
(13, 2, 5),
(13, 2, 6),
(13, 2, 7),
(13, 2, 8),
(14, 2, 5),
(14, 2, 6),
(14, 2, 7),
(14, 2, 8),
(15, 2, 5),
(15, 2, 6),
(15, 2, 7),
(15, 2, 8),
(16, 2, 5),
(16, 2, 6),
(16, 2, 7),
(16, 2, 8),
(17, 2, 5),
(17, 2, 6),
(17, 2, 7),
(17, 2, 8),
(18, 2, 5),
(18, 2, 6),
(18, 2, 7),
(18, 2, 8),
(57, 4, 9),
(57, 4, 10),
(57, 4, 11),
(57, 4, 12),
(58, 4, 9),
(58, 4, 10),
(58, 4, 11),
(58, 4, 12),
(59, 4, 9),
(59, 4, 10),
(59, 4, 11),
(59, 4, 12),
(60, 4, 9),
(60, 4, 10),
(60, 4, 11),
(60, 4, 12),
(61, 4, 9),
(61, 4, 10),
(61, 4, 11),
(61, 4, 12),
(62, 4, 9),
(62, 4, 10),
(62, 4, 11),
(62, 4, 12),
(63, 4, 9),
(63, 4, 10),
(63, 4, 11),
(63, 4, 12),
(64, 4, 9),
(64, 4, 10),
(64, 4, 11),
(64, 4, 12),
(65, 4, 9),
(65, 4, 10),
(65, 4, 11),
(65, 4, 12),
(118, 1, 1),
(118, 1, 2),
(118, 1, 3),
(118, 1, 4),
(129, 1, 1),
(129, 1, 2),
(129, 1, 3),
(129, 1, 4),
(131, 1, 1),
(131, 1, 2),
(131, 1, 3),
(131, 1, 4),
(137, 1, 1),
(137, 1, 2),
(137, 1, 3),
(137, 1, 4),
(138, 1, 1),
(138, 1, 2),
(138, 1, 3),
(138, 1, 4),
(140, 1, 1),
(140, 1, 2),
(140, 1, 3),
(140, 1, 4),
(142, 1, 1),
(142, 1, 2),
(142, 1, 3),
(142, 1, 4),
(143, 1, 1),
(143, 1, 2),
(143, 1, 3),
(143, 1, 4),
(144, 1, 1),
(144, 1, 2),
(144, 1, 3),
(144, 1, 4),
(145, 1, 1),
(145, 1, 2),
(145, 1, 3),
(145, 1, 4),
(146, 20, 25),
(146, 20, 26),
(146, 20, 27),
(146, 20, 28),
(147, 20, 25),
(147, 20, 26),
(147, 20, 27),
(147, 20, 28),
(150, 20, 25),
(150, 20, 26),
(150, 20, 27),
(150, 20, 28),
(154, 20, 25),
(154, 20, 26),
(154, 20, 27),
(154, 20, 28),
(158, 20, 25),
(158, 20, 26),
(158, 20, 27),
(158, 20, 28),
(159, 20, 25),
(159, 20, 26),
(159, 20, 27),
(159, 20, 28),
(167, 20, 25),
(167, 20, 26),
(167, 20, 27),
(167, 20, 28),
(168, 20, 25),
(168, 20, 26),
(168, 20, 27),
(168, 20, 28),
(169, 20, 25),
(169, 20, 26),
(169, 20, 27),
(169, 20, 28),
(170, 20, 25),
(170, 20, 26),
(170, 20, 27),
(170, 20, 28),
(172, 20, 25),
(172, 20, 26),
(172, 20, 27),
(172, 20, 28),
(173, 20, 25),
(173, 20, 26),
(173, 20, 27),
(173, 20, 28),
(174, 20, 25),
(174, 20, 26),
(174, 20, 27),
(174, 20, 28),
(176, 20, 25),
(176, 20, 26),
(176, 20, 27),
(176, 20, 28),
(177, 20, 25),
(177, 20, 26),
(177, 20, 27),
(177, 20, 28),
(178, 20, 25),
(178, 20, 26),
(178, 20, 27),
(178, 20, 28),
(179, 20, 25),
(179, 20, 26),
(179, 20, 27),
(179, 20, 28),
(189, 19, 21),
(189, 19, 22),
(189, 19, 23),
(189, 19, 24),
(190, 19, 21),
(190, 19, 22),
(190, 19, 23),
(190, 19, 24),
(191, 19, 21),
(191, 19, 22),
(191, 19, 23),
(191, 19, 24),
(192, 19, 21),
(192, 19, 22),
(192, 19, 23),
(192, 19, 24),
(193, 19, 21),
(193, 19, 22),
(193, 19, 23),
(193, 19, 24),
(194, 19, 21),
(194, 19, 22),
(194, 19, 23),
(194, 19, 24),
(195, 19, 21),
(195, 19, 22),
(195, 19, 23),
(195, 19, 24),
(196, 19, 21),
(196, 19, 22),
(196, 19, 23),
(196, 19, 24),
(197, 5, 13),
(197, 5, 14),
(197, 5, 15),
(197, 5, 16),
(198, 5, 13),
(198, 5, 14),
(198, 5, 15),
(198, 5, 16),
(199, 5, 13),
(199, 5, 14),
(199, 5, 15),
(199, 5, 16),
(200, 5, 13),
(200, 5, 14),
(200, 5, 15),
(200, 5, 16),
(201, 5, 13),
(201, 5, 14),
(201, 5, 15),
(201, 5, 16),
(202, 5, 13),
(202, 5, 14),
(202, 5, 15),
(202, 5, 16),
(204, 5, 13),
(204, 5, 14),
(204, 5, 15),
(204, 5, 16),
(205, 5, 13),
(205, 5, 14),
(205, 5, 15),
(205, 5, 16),
(223, 5, 13),
(223, 5, 14),
(223, 5, 15),
(223, 5, 16),
(227, 5, 13),
(227, 5, 14),
(227, 5, 15),
(227, 5, 16),
(228, 5, 13),
(228, 5, 14),
(228, 5, 15),
(228, 5, 16),
(269, 17, 17),
(269, 17, 18),
(269, 17, 19),
(269, 17, 20),
(270, 17, 17),
(270, 17, 18),
(270, 17, 19),
(270, 17, 20),
(271, 17, 17),
(271, 17, 18),
(271, 17, 19),
(271, 17, 20),
(272, 17, 17),
(272, 17, 18),
(272, 17, 19),
(272, 17, 20),
(273, 17, 17),
(273, 17, 18),
(273, 17, 19),
(273, 17, 20),
(274, 17, 17),
(274, 17, 18),
(274, 17, 19),
(274, 17, 20),
(275, 17, 17),
(275, 17, 18),
(275, 17, 19),
(275, 17, 20),
(276, 17, 17),
(276, 17, 18),
(276, 17, 19),
(276, 17, 20),
(283, 17, 17),
(283, 17, 18),
(283, 17, 19),
(283, 17, 20),
(284, 1, 1),
(284, 1, 2),
(284, 1, 3),
(284, 1, 4);

-- --------------------------------------------------------

--
-- Table structure for table `subjects`
--

DROP TABLE IF EXISTS `subjects`;
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

DROP TABLE IF EXISTS `teachers_classes`;
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
(1, 1, 4, 1, '2015-03-23 12:32:00', '2015-04-29 09:00:21'),
(2, 48, 3, 1, '2015-03-23 12:32:28', '2015-03-23 11:32:28'),
(3, 1, 2, 1, '2015-03-23 12:32:49', '2015-04-29 09:00:10'),
(4, 50, 1, 1, '2015-03-23 12:35:55', '2015-03-23 11:36:11'),
(5, 54, 5, 1, '2015-03-23 12:36:41', '2015-03-23 11:36:41'),
(6, 6, 7, 1, '2015-03-23 12:37:27', '2015-04-29 09:00:51'),
(7, 52, 10, 1, '2015-03-23 12:38:31', '2015-03-23 11:38:31'),
(8, 23, 9, 1, '2015-03-23 12:38:52', '2015-03-23 11:38:52'),
(9, 44, 13, 1, '2015-03-23 12:43:15', '2015-03-23 11:43:15'),
(10, 30, 14, 1, '2015-03-23 12:43:34', '2015-03-23 11:43:34'),
(11, 43, 12, 1, '2015-03-23 12:44:30', '2015-03-23 11:44:30'),
(12, 46, 11, 1, '2015-03-23 12:44:57', '2015-03-23 11:44:57'),
(13, 53, 15, 1, '2015-03-23 12:45:16', '2015-03-23 11:45:21'),
(14, 62, 20, 1, '2015-03-23 12:53:48', '2015-03-23 11:53:48'),
(15, 1, 19, 1, '2015-03-23 12:54:56', '2015-04-29 09:01:18'),
(16, 1, 17, 1, '2015-03-23 12:55:08', '2015-04-29 09:01:14'),
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
DROP VIEW IF EXISTS `teachers_classviews`;
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

DROP TABLE IF EXISTS `teachers_subjects`;
CREATE TABLE IF NOT EXISTS `teachers_subjects` (
`teachers_subjects_id` int(11) NOT NULL,
  `employee_id` int(11) DEFAULT NULL,
  `class_id` int(11) DEFAULT NULL,
  `subject_classlevel_id` int(11) DEFAULT NULL,
  `assign_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=13 ;

--
-- Dumping data for table `teachers_subjects`
--

INSERT INTO `teachers_subjects` (`teachers_subjects_id`, `employee_id`, `class_id`, `subject_classlevel_id`, `assign_date`) VALUES
(1, 19, 17, 17, '2015-04-29 09:05:11'),
(2, 19, 19, 21, '2015-04-29 09:05:16'),
(3, 1, 19, 24, '2015-04-29 09:05:31'),
(4, 1, 20, 28, '2015-04-29 09:05:40'),
(5, 1, 20, 26, '2015-04-29 09:05:49'),
(6, 1, 19, 22, '2015-04-29 09:05:56'),
(7, 19, 19, 23, '2015-04-29 09:06:46'),
(8, 19, 20, 27, '2015-04-29 09:06:51'),
(9, 19, 2, 5, '2015-04-29 09:07:21'),
(10, 19, 4, 9, '2015-04-29 09:07:25'),
(11, 1, 4, 10, '2015-04-29 09:07:36'),
(12, 1, 2, 6, '2015-04-29 09:07:43');

-- --------------------------------------------------------

--
-- Stand-in structure for view `teachers_subjectsviews`
--
DROP VIEW IF EXISTS `teachers_subjectsviews`;
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

DROP TABLE IF EXISTS `user_roles`;
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

DROP TABLE IF EXISTS `users`;
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
(2, 'PAR0001', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'Ogbuchi Stanley', 1, 'sponsors/1.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 02:11:34', '2015-04-22 10:02:43'),
(3, 'STF0001', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'Dotun Kudaisi', 1, 'employees/1.png', 7, 'ADM_USERS', 1, 1, '2015-03-23 11:09:03', '2015-04-22 10:03:46'),
(5, 'STF0003', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'Abikoye J.', 3, 'employees/3.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:40:35', '2015-04-22 10:03:46'),
(6, 'STF0004', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'ADEGOKE M.', 4, 'employees/4.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:42:34', '2015-04-22 10:03:46'),
(7, 'STF0005', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'ADEYEMI B.', 5, 'employees/5.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:47:32', '2015-04-22 10:03:46'),
(8, 'STF0006', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'ADISA S.', 6, 'employees/6.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:48:42', '2015-04-22 10:03:46'),
(9, 'STF0007', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'AIGBOMIAN A.', 7, 'employees/7.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:49:44', '2015-04-22 10:03:46'),
(10, 'STF0008', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'AJAYI G.', 8, 'employees/8.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:53:19', '2015-04-22 10:03:46'),
(11, 'PAR0002', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'ADENIRAN JOSEPH', 2, 'sponsors/2.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 06:57:19', '2015-04-22 10:02:43'),
(12, 'STF0009', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'AKINROLABU B.', 9, 'employees/9.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:57:44', '2015-04-22 10:03:46'),
(13, 'STF0010', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'AKINYEMI D.', 10, 'employees/10.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:58:39', '2015-04-22 10:03:46'),
(14, 'PAR0003', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'ATUNRASE BANKOLE', 3, 'sponsors/3.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 06:58:57', '2015-04-22 10:02:43'),
(15, 'STF0011', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'ALIU Z.', 11, 'employees/11.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 06:59:28', '2015-04-22 10:03:46'),
(16, 'PAR0004', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'BAIYEKUSI PHOS BAYOWA', 4, 'sponsors/4.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:00:53', '2015-04-22 10:02:43'),
(17, 'STF0012', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'ANJORIN A.', 12, 'employees/12.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:00:59', '2015-04-22 10:03:46'),
(18, 'STF0013', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'ARAOYE O.', 13, 'employees/13.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:11:12', '2015-04-22 10:03:46'),
(19, 'PAR0005', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'BAKRE OLUWATOFARATI DAVID', 5, 'sponsors/5.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:02:41', '2015-04-22 10:02:43'),
(20, 'STF0014', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'AWOGBADE A.', 14, 'employees/14.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:23:50', '2015-04-22 10:03:46'),
(21, 'PAR0006', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'BALOGUN MOSES', 6, 'sponsors/6.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:04:50', '2015-04-22 10:02:43'),
(22, 'STF0015', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'AYEGBUSI ADERONKE', 15, 'employees/15.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:05:29', '2015-04-22 10:03:46'),
(23, 'STF0016', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'AZEEZ B.', 16, 'employees/16.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:17:09', '2015-04-22 10:03:46'),
(24, 'STF0017', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'AZIAKA D.', 17, 'employees/17.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 04:50:23', '2015-04-22 10:03:46'),
(25, 'STF0018', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'BABALOLA A.', 18, 'employees/18.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:08:50', '2015-04-22 10:03:46'),
(26, 'PAR0007', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'BAYOKO NATHAN', 7, 'sponsors/7.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:12:26', '2015-04-22 10:02:43'),
(27, 'STF0019', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'BABATOPE F.', 19, 'employees/19.jpg', 3, 'STF_USERS', 1, 1, '2015-03-19 07:12:59', '2015-04-22 10:03:46'),
(28, 'STF0020', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'BADERIN .', 20, 'employees/20.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:14:15', '2015-04-22 10:03:46'),
(29, 'STF0021', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'BETIKU INCREASE ', 21, 'employees/21.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:14:58', '2015-04-22 10:03:46'),
(30, 'STF0022', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'DADA B.', 22, 'employees/22.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:17:57', '2015-04-22 10:03:46'),
(31, 'PAR0008', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'EGBEDEYI SAMUEL', 8, 'sponsors/8.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:20:00', '2015-04-22 10:02:43'),
(32, 'PAR0009', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'HENRY-NKEKI DAVID', 9, 'sponsors/9.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:36:10', '2015-04-22 10:02:43'),
(33, 'STF0023', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'EKPUH M.', 23, 'employees/23.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:25:45', '2015-04-22 10:03:46'),
(34, 'PAR0010', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'IBILOLA DAVID', 10, 'sponsors/10.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:37:47', '2015-04-22 10:02:43'),
(35, 'STF0024', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'EKUNBOYEJO E.', 24, 'employees/24.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:37:49', '2015-04-22 10:03:46'),
(36, 'STF0025', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'EWERE L.', 25, 'employees/25.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:39:13', '2015-04-22 10:03:46'),
(37, 'STF0026', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'FAKOLUJO E. ', 26, 'employees/26.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:39:46', '2015-04-22 10:03:46'),
(38, 'PAR0011', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'NICK-IBITOYE  OLANREWAJU', 11, 'sponsors/11.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:42:44', '2015-04-22 10:02:43'),
(39, 'STF0027', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'FAMAKINWA J.', 27, 'employees/27.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:46:36', '2015-04-22 10:03:46'),
(40, 'PAR0012', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'NKUME-ANYIGOR  VICTOR', 12, 'sponsors/12.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:46:39', '2015-04-22 10:02:43'),
(41, 'STF0028', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'GBADAMOSI ABIODUN', 28, 'employees/28.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:50:51', '2015-04-22 10:03:46'),
(42, 'PAR0013', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OFOEGBUNAM CHUKWUKA', 13, 'sponsors/13.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:51:38', '2015-04-22 10:02:43'),
(43, 'STF0029', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'IBITAYO M.', 29, 'employees/29.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 07:53:51', '2015-04-22 10:03:46'),
(44, 'PAR0014', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OGHOORE JOSHUA', 14, 'sponsors/14.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:55:38', '2015-04-22 10:02:43'),
(45, 'STF0030', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'IKEME N.', 30, 'employees/30.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-24 12:22:36', '2015-04-22 10:03:46'),
(46, 'PAR0015', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OLAGUNJU ADEYEMI', 15, 'sponsors/15.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 07:57:44', '2015-04-22 10:02:43'),
(48, 'PAR0016', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OLATUNBOSUN OLANREWAJU JOSEPH', 16, 'sponsors/16.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 08:01:47', '2015-04-22 10:02:43'),
(49, 'STF0032', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'JOSEPH F.', 32, 'employees/32.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:16:03', '2015-04-22 10:03:46'),
(50, 'PAR0017', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'YUSUF AYODELE', 17, 'sponsors/17.jpg', 1, 'PAR_USERS', 1, 1, '2015-03-19 08:03:41', '2015-04-22 10:02:43'),
(51, 'STF0033', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'KOLORUKO L.', 33, 'employees/33.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 08:32:09', '2015-04-22 10:03:46'),
(52, 'STF0034', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'LIADI A.', 34, 'employees/34.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 08:10:38', '2015-04-22 10:03:46'),
(53, 'STF0035', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MEMUD OLANREWAJU', 35, 'employees/35.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 08:11:09', '2015-04-22 10:03:46'),
(54, 'STF0036', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'MUDASIRU T.', 36, 'employees/36.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-19 08:15:50', '2015-04-22 10:03:46'),
(57, 'STF0038', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'NOAH F.', 38, 'employees/38.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:27:18', '2015-04-22 10:03:46'),
(58, 'STF0039', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'NOSIKE D.', 39, 'employees/39.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 12:00:40', '2015-04-22 10:03:46'),
(59, 'STF0040', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'ADEOGUN .', 40, 'employees/40.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:59:22', '2015-04-22 10:03:46'),
(60, 'STF0041', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'NWANI  J.', 41, 'employees/41.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:09:36', '2015-04-22 10:03:46'),
(61, 'STF0042', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'NWANKWO U.', 42, 'employees/42.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:16:32', '2015-04-22 10:03:46'),
(62, 'STF0043', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OBAJINMI  B.', 43, 'employees/43.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:14:57', '2015-04-22 10:03:46'),
(63, 'STF0044', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OBIANO C.', 44, 'employees/44.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-24 01:21:59', '2015-04-22 10:03:46'),
(64, 'STF0045', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OGUNBOWALE A.', 45, 'employees/45.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:15:41', '2015-04-22 10:03:46'),
(65, 'STF0046', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OGUNLEYE M.', 46, 'employees/46.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:15:20', '2015-04-22 10:03:46'),
(66, 'STF0047', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OGUNSOLA M.', 47, 'employees/47.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:24:14', '2015-04-22 10:03:46'),
(67, 'STF0048', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OJENIYI A.', 48, 'employees/48.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:25:04', '2015-04-22 10:03:46'),
(68, 'STF0049', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OJETUNDE S.', 49, 'employees/49.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:27:16', '2015-04-22 10:03:46'),
(69, 'STF0050', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OJO T.', 50, 'employees/50.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:20:27', '2015-04-22 10:03:46'),
(70, 'STF0051', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OKECHUKWU-OMOLUABI B.', 51, 'employees/51.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:30:43', '2015-04-22 10:03:46'),
(71, 'STF0052', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OKINI,  I.', 52, 'employees/52.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:20:58', '2015-04-22 10:03:46'),
(72, 'STF0053', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OLAKANLE O.', 53, 'employees/53.jpg', 4, 'ICT_USERS', 1, 0, '2015-03-23 02:13:32', '2015-04-22 10:03:46'),
(73, 'STF0054', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OLATUNDE T.', 54, 'employees/54.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:19:00', '2015-04-22 10:03:46'),
(74, 'STF0055', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OLAWOLE O.', 55, 'employees/55.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:47:53', '2015-04-22 10:03:46'),
(75, 'STF0056', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'ORIMOLADE K.', 56, 'employees/56.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:48:44', '2015-04-22 10:03:46'),
(76, 'STF0057', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'OWADOYE  A.', 57, 'employees/57.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:49:38', '2015-04-22 10:03:46'),
(77, 'STF0058', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'SOKOYA T.', 58, 'employees/58.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:50:21', '2015-04-22 10:03:46'),
(78, 'STF0059', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'TEMURU S.', 59, 'employees/59.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:23:10', '2015-04-22 10:03:46'),
(79, 'STF0060', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'UADEMEVBO O.', 60, 'employees/60.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:27:44', '2015-04-22 10:03:46'),
(80, 'STF0061', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'UDOKPORO L.', 61, 'employees/61.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:55:54', '2015-04-22 10:03:46'),
(81, 'STF0062', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'UMAR-MUHAMMED A.', 62, 'employees/62.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-23 12:22:39', '2015-04-22 10:03:46'),
(82, 'STF0063', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'USHIE G.', 63, 'employees/63.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-21 05:59:08', '2015-04-22 10:03:46'),
(83, 'STF0064', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'Okafor Emmanuel', 64, 'employees/64.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-22 02:15:37', '2015-04-22 10:03:46'),
(91, 'STF0065', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'Salau .', 65, 'employees/65.jpg', 4, 'ICT_USERS', 1, 1, '2015-03-24 01:16:39', '2015-04-22 10:03:46'),
(92, 'PAR0025', '$2a$10$XEGtrkPpds9LoNDuUYY1Ke8tZ6BK6MWJJLoNH93mSVYsRRAD43rYi', 'Ajayi Oladapo', 25, 'sponsors/25.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 10:17:45', '2015-04-22 10:02:43'),
(93, 'PAR0026', '$2a$10$H3h14rHKrZA4uIdTCt57AeEkxzUDMZOEfeN913I0dxoK.UhA9cb7W', 'Opeyemi Opeyemi', 26, 'sponsors/26.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 10:23:45', '2015-04-22 10:02:43'),
(96, 'PAR0029', '$2a$10$lyPMJZZxKVLYidIubyQKyON9MtaL5hDCr.I18/cYP37ZMJ08Daevu', 'Williams Adegboyega', 29, 'sponsors/29.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 10:49:42', '2015-04-22 10:02:43'),
(97, 'PAR0030', '$2a$10$EMJz6SeQCFpeM.pAuyzSD.Vw4auF53bTGYHl5L4e6nhGEfTokJLji', 'Adealu Ifeoluwa', 30, 'sponsors/30.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-24 11:08:11', '2015-04-22 10:02:43'),
(99, 'PAR0032', '$2a$10$3Rxvow0am4ntaCHg86p2suVdW2prpEZ2gUjzlV3yksAvc0wB9V93S', 'ABADI KEME', 32, 'sponsors/32.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:21:47', '2015-04-22 10:02:43'),
(101, 'PAR0034', '$2a$10$7HqcYtG.tY317JRbSzHPCOI7IiGM.3hjmNahs6H9FlioaHjWT/tWC', 'AMARA EBIKABOERE', 34, 'sponsors/34.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:25:10', '2015-04-22 10:02:43'),
(102, 'PAR0035', '$2a$10$nvgXEOgxJkdBsHPwCahKMOCPq1SMQi8ngqOx0j63Qm2LeVbZGmHp6', 'ANIWETA-NEZIANYA CHIAMAKA', 35, 'sponsors/35.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:26:48', '2015-04-22 10:02:43'),
(103, 'PAR0036', '$2a$10$ii7pvhtQ7Fb9tbhog38EP.nWMjD/AuxUcLvOVl7mmnLIO6mb/wDs.', 'BAGOU KENDRAH', 36, 'sponsors/36.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:28:15', '2015-04-22 10:02:43'),
(104, 'PAR0037', '$2a$10$C3jcVHqYNAlvihXuHaz0Cuc/5UOVwVTCTmOLvExkjefUf8S0sdzhq', 'ERIVWODE OKEOGHENE', 37, 'sponsors/37.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:29:35', '2015-04-22 10:02:43'),
(105, 'PAR0038', '$2a$10$R/zjgrO5dGkQhCcHlELbw.y6HZTNX0hwpymynCqzd7KBwxfd78le6', 'GEORGEWILL AYEBANENGIYEFA', 38, 'sponsors/38.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:30:56', '2015-04-22 10:02:43'),
(106, 'PAR0039', '$2a$10$UTArCrnkCqIsoIXqAybWYetG7.1wszSs6zw4oWt8IiRXYo/l4Tk8.', 'ITSEUWA  ROSEMARY', 39, 'sponsors/39.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:32:20', '2015-04-22 10:02:43'),
(107, 'PAR0040', '$2a$10$peB4hVYgovLAJOVnV39Wg.40zVrrmHE0gfyOia34JAzVsBPjm0N2K', 'JOB VICTORIA', 40, 'sponsors/40.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:33:22', '2015-04-22 10:02:43'),
(108, 'PAR0041', '$2a$10$2HL35v.3Djpm2JgJ4fwIPejk.A6D4tGOSK7FFoPhIRlzndMXRO/LO', 'KALAYOLO HAPPINESS', 41, 'sponsors/41.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:34:25', '2015-04-22 10:02:43'),
(109, 'PAR0042', '$2a$10$0IwnUjzUa5oQVxqtjSlNrOHJRV6.hzoolP0pWdyzbgC4Z3F8C8oL6', 'MAZI ONISOKIE', 42, 'sponsors/42.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:36:03', '2015-04-22 10:02:43'),
(110, 'PAR0043', '$2a$10$fRVFFpziorjLeJA./7XIDu/JD9h34UKrEOatT4Kvfu2zl9w5HoPhW', 'NATHANIEL EVELYN', 43, 'sponsors/43.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:37:04', '2015-04-22 10:02:43'),
(111, 'PAR0044', '$2a$10$nsOpDhgIC6BK/GZtbKNSf.JnS5z1556eiQfM.pVc1I9n0nP3kD7Ne', 'OBUBE OYINKANSOLA', 44, 'sponsors/44.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:37:58', '2015-04-22 10:02:43'),
(112, 'PAR0045', '$2a$10$6h25TFlnqTtqc2WCQmpzeO5a7Q8FNrAgs3OtGRafiMgYzSBz.6NlO', 'OKE OYINDAMOLA', 45, 'sponsors/45.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:38:54', '2015-04-22 10:02:43'),
(113, 'PAR0046', '$2a$10$/7BQVyd7.h4vzh7x28Sm5OTyl.IMEX4UumRUK7j6GaaunBDumMn8u', 'Otori Jimoh', 46, 'sponsors/46.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 11:39:32', '2015-04-22 10:02:43'),
(114, 'PAR0047', '$2a$10$ZU1CVjXLVRClVXC7dVyoEO1mUpB9CZ38l5zEo3Gpo5zV1uXyzMvCW', 'OKOYE CHISOM', 47, 'sponsors/47.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:39:55', '2015-04-22 10:02:43'),
(115, 'PAR0048', '$2a$10$FTeUVVDKIVUSgNlbRz3FGe7fVKlFXlAZUzGBE8aPQlaxX4a6AEW6y', 'Salau Funke', 48, 'sponsors/48.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 11:41:13', '2015-04-22 10:02:43'),
(116, 'PAR0049', '$2a$10$cEOLdf7zUKCJpF9AE.G6AOu9WfZAuLjfAIm.rn/KQ0nk9.eUUcjuC', 'TELIMOYE IBEINMO', 49, 'sponsors/49.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:41:32', '2015-04-22 10:02:43'),
(117, 'PAR0050', '$2a$10$h4E/s/F5FKb2FoJlI8dIm.1lueAuGO9a.xElz8OWL2Dr7Z1vykFEG', 'Adealu Moruf', 50, 'sponsors/50.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 11:42:50', '2015-04-22 10:02:43'),
(118, 'PAR0051', '$2a$10$Ew14Q8oWiWvKs0GmYmzNeOAkd7joAodRjIHykD3qwyHXPD7lNCxSG', 'WAIBITE ENDURANCE', 51, 'sponsors/51.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:44:42', '2015-04-22 10:02:43'),
(119, 'PAR0052', '$2a$10$qEUuBilRIwpIfTqKeYN0C..BYhc8tn4IO3AREVzQ8ZOLyc9mYClti', 'Ojo Oluwagbenga', 52, 'sponsors/52.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 11:45:33', '2015-04-22 10:02:43'),
(120, 'PAR0053', '$2a$10$eJDpIRuEuFZTPeAwM7cUP.Oe9RPhP6HXJn.o3v3/6sQ0cdWxVq2P2', 'WILLIAMS IBUKUN', 53, 'sponsors/53.jpg', 1, 'PAR_USERS', 1, 30, '2015-03-24 11:45:38', '2015-04-22 10:02:43'),
(121, 'PAR0054', '$2a$10$7KaLmNX8NFXZkcOWunnN0ecAytqbk.crKOfzcz5PW5jR5ou.itbNW', 'Oloyede Adekunle', 54, 'sponsors/54.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 11:46:23', '2015-04-22 10:02:43'),
(122, 'PAR0055', '$2a$10$oV/AVv3EqA6IMpld45Arp.y1vpR0fN7kWPbf2B3Ixhn/UeOErG3ES', 'Abioye Oyinlade', 55, 'sponsors/55.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 11:47:30', '2015-04-22 10:02:43'),
(123, 'PAR0056', '$2a$10$DTxpbssOuoa8SoCpp7x9uOMMKkMmljbDrtEMa7z9EuRjMZ5v/stgq', 'Odesola Jelili', 56, 'sponsors/56.jpg', 1, 'PAR_USERS', 1, 53, '2015-03-24 11:48:22', '2015-04-22 10:02:43'),
(124, 'PAR0057', '$2a$10$EM7.knWxlWaQNk3E7f9C2uAbW2/VAv0wJHiqO9NJt60oOR9ox8F4G', 'ADEOSUN Oladapo', 57, 'sponsors/57.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:17:24', '2015-04-22 10:02:43'),
(125, 'PAR0058', '$2a$10$/hB3cJl9sHstEBcq3g8qfO4zMsNGA5T34caO0p2n3zlbSrS.91ef2', 'DADA MUBARAK', 58, 'sponsors/58.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:18:11', '2015-04-22 10:02:43'),
(126, 'PAR0059', '$2a$10$Ja827GWpJejlQolAb5HR3O7J5VsritCK29yCJe8XaRBTYIMYySdb2', 'ADEDOTUN MICHEAL', 59, 'sponsors/59.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:19:09', '2015-04-22 10:02:43'),
(127, 'PAR0060', '$2a$10$sCmeKHC4x0viaeDLBosdj.2RdIQ/gAFa.I/T1ri6DZjXw9v7wy4Ze', 'AGUNBIADE DEBORAH', 60, 'sponsors/60.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:21:48', '2015-04-22 10:02:43'),
(128, 'PAR0061', '$2a$10$nTAO.OfWBVTd9hmRUmy7ze1yvn/RUQwJ4P.ZuaxPjQjGm2.T3DTTa', 'HAMZAT Adekunle', 61, 'sponsors/61.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:22:32', '2015-04-22 10:02:43'),
(129, 'PAR0062', '$2a$10$FaM9baGYD3mL.IXsF.091O/lBSSc03TQH7kgAc9ozKnpno7KM8BE6', 'LALA EMMANUEL', 62, 'sponsors/62.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:23:09', '2015-04-22 10:02:43'),
(130, 'PAR0063', '$2a$10$ZiHebrEINMUinsGCVdJXlO85R2EvWpiZm96CRQ66P4cpak6d5AC06', 'OKESINA ADESOJI', 63, 'sponsors/63.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:23:48', '2015-04-22 10:02:43'),
(131, 'PAR0064', '$2a$10$2P6s7y7y2Tqgmdf1GD2Xl.5oYwMJIiGf0ZhNzKHfLGmbHxKbtGevO', 'OJO JOSEPH', 64, 'sponsors/64.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:24:30', '2015-04-22 10:02:43'),
(132, 'PAR0065', '$2a$10$dZqLZYwOmtbAnPlEQnKoFeBTVL1m70lNytT1VOePpCVEusRAyyzym', 'ADENIYI IBAZEBO', 65, 'sponsors/65.jpg', 1, 'PAR_USERS', 1, 52, '2015-03-24 12:40:25', '2015-04-22 10:02:43'),
(133, 'PAR0066', '$2a$10$IRtfqxhFygmNmHwqyjWiaupjf2V2MXVuDFspWtavAbu3rnfyoacpC', 'Azeez Olufemi', 66, 'sponsors/66.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:49:56', '2015-04-22 10:02:43'),
(134, 'PAR0067', '$2a$10$nEQfT1ivMEyQ1gXd2SKvde0bo.oqwrPnFR6VZxbPfMZy14dlZo9Ze', 'Bello Tajudeen', 67, 'sponsors/67.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:50:43', '2015-04-22 10:02:43'),
(135, 'PAR0068', '$2a$10$1BR8NszfIVfpxR19QL40Ke.cXrT2o3L0hyx3YDEXHHu016t3I7V1a', 'Bello Aderemi', 68, 'sponsors/68.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:51:49', '2015-04-22 10:02:43'),
(136, 'PAR0069', '$2a$10$L4gpglC8obH3bPW6YjA2dOy0LMJgsrNUWn07LEd.emtIVHkUZZzDW', 'Bribena Kelvin', 69, 'sponsors/69.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:52:39', '2015-04-22 10:02:43'),
(137, 'PAR0070', '$2a$10$77sa3YzOGL/sIk0YufC1/.QKZIl6yLyk2K7gupA/zPmRuePeyyaua', 'Folorunso Isaac', 70, 'sponsors/70.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:55:00', '2015-04-22 10:02:43'),
(138, 'PAR0071', '$2a$10$xB0NTUN55OsdLQAVCYhuwujx.vraJ.7pyNmxiegMTL98qNTjT6cY6', 'Ogundele Amos', 71, 'sponsors/71.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:55:31', '2015-04-22 10:02:43'),
(139, 'PAR0072', '$2a$10$Ya4zZs5yzhUZ8EhPj8n7G.eSEgmtJCuRr/oKXDrdsOJAhc22EeAzS', 'Olaoye Oyekanmi', 72, 'sponsors/72.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:56:12', '2015-04-22 10:02:43'),
(140, 'PAR0073', '$2a$10$5a/W5Kc7uRSa8P3qYA6sOOOjuSfSHPwg/9q6jf6uUDH9jqZH/OfaS', 'Onyebuchi Edwin', 73, 'sponsors/73.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 12:57:04', '2015-04-22 10:02:43'),
(141, 'PAR0074', '$2a$10$rUMBw1IuL4mlq.FgWU8ZRuMbH6jg9Keq14Phgi2pM2GIpEQ.D6psS', 'Eze Adaobi', 74, 'sponsors/74.jpg', 1, 'PAR_USERS', 1, 14, '2015-03-24 01:00:05', '2015-04-22 10:02:43'),
(142, 'PAR0075', '$2a$10$CxDGazSLClycz8OEZ7Z2yOeg8cULVAtI3XVTKuhGC4j0LNWf6daWW', 'Ibetei Humphrey', 75, 'sponsors/75.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:24:31', '2015-04-22 10:02:43'),
(143, 'PAR0076', '$2a$10$82a3sbprJBvvlSk4NMMf3eOy/w2XII8dHkIOaa71atkJfqXhBaN8e', 'Dede Reginald', 76, 'sponsors/76.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:25:40', '2015-04-22 10:02:43'),
(144, 'PAR0077', '$2a$10$51loLv61H1j/UFDlrVI9D.O825sSFxI/6eNkBCZ4B.VqSratQ5FjW', 'Abdou Fatiou', 77, 'sponsors/77.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:28:24', '2015-04-22 10:02:43'),
(145, 'PAR0078', '$2a$10$x5HWC95eFTqKIvJ6QU.HxeJ6eUjVLYaEfTugZLBP2ckCVi4HP7U9G', 'Obireke Osoru', 78, 'sponsors/78.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:29:12', '2015-04-22 10:02:43'),
(146, 'PAR0079', '$2a$10$lQj.64hq6CVUCIqlnW/3XefP643wKzQiW/Q09qXMU5rDxLV8vYN42', 'Umoru Solomon', 79, 'sponsors/79.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:30:09', '2015-04-22 10:02:43'),
(147, 'PAR0080', '$2a$10$VM.QdDc2YdWHwZEb2lI/uO0GafXRQciP38FHx7oOJEZhdxxikPbkq', 'Nanakede Smdoth', 80, 'sponsors/80.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:32:02', '2015-04-22 10:02:43'),
(148, 'PAR0081', '$2a$10$uaQOiGy6rmhQhPwuEYJQZ.nQzM.OtRcFxw.UgkF1yStxb.7GkV7Fq', 'puragha Bob', 81, 'sponsors/81.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:33:19', '2015-04-22 10:02:43'),
(149, 'PAR0082', '$2a$10$D6JDBdfuSIUS/L4Nk5jzfO7JoU7irvzisfOAGNgcbvFa1mZKHEjOm', 'Soroh Anthony', 82, 'sponsors/82.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:34:07', '2015-04-22 10:02:43'),
(150, 'PAR0083', '$2a$10$l9eiJKyjBsYPiO.MSM84MeCVp9S2xhVnoFnWOhjoZacKWSDvKZBzy', 'Maddocks Christopher', 83, 'sponsors/83.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:34:59', '2015-04-22 10:02:43'),
(151, 'PAR0084', '$2a$10$nFwsUwDeewpgGW4DtmeCOe2Y2Kf7nzlvLTCm6j44WcXzIJtYzpM1W', 'Isibor Osahon', 84, 'sponsors/84.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:35:43', '2015-04-22 10:02:43'),
(152, 'PAR0085', '$2a$10$xBjUrS/nSslelo12HCsSz.Jb384IJ6563X3Vl7utfkJ3Zn0Sk.k2m', 'Zolo Joshua', 85, 'sponsors/85.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:37:22', '2015-04-22 10:02:43'),
(153, 'PAR0086', '$2a$10$X4l0CqV9pHWBe3UAwnDVEObPPns1e8mzebSGkc6VUmdO7gizoBcQa', 'Koroye  Ebikabo', 86, 'sponsors/86.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:38:31', '2015-04-22 10:02:43'),
(154, 'PAR0087', '$2a$10$gXnY6k8ZOTeUz6y8fuYoMOh.9Jk5pt2zWnFEvjSiYB4ZwA6o/xjYO', 'Amakedi Moneyman', 87, 'sponsors/87.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:39:27', '2015-04-22 10:02:43'),
(155, 'PAR0088', '$2a$10$dgY8H031INFUy/c3T5VthOYR1GZN0mFpN3IhmnIkXp85JRAB13pGG', 'Azugha Sunday', 88, 'sponsors/88.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:40:04', '2015-04-22 10:02:43'),
(156, 'PAR0089', '$2a$10$hQ9UlVUM3.m6Zo/6H804ROtNdJc6hlqbEryzWlYHc.NZQwLUwiOEG', 'Abdullahi Saadu', 89, 'sponsors/89.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:40:06', '2015-04-22 10:02:43'),
(157, 'PAR0090', '$2a$10$JUdIcBx4VGzd0d7B9MIqFeREIFVfnNk/Lg62SKet6jLmjyOUlLW.G', 'Inenemo-Usman Abdul', 90, 'sponsors/90.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:41:00', '2015-04-22 10:02:43'),
(158, 'PAR0091', '$2a$10$zrWFqdEyiTIDs7RO2JeNUeQnKGuox0SP7/vzo1Ox4cRdbp5b3Wcg.', 'adeyemi J.A', 91, 'sponsors/91.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:41:01', '2015-04-22 10:02:43'),
(159, 'PAR0092', '$2a$10$hGVSMbSGBcP2i77pyJNoNumrqy6pHkl2DBADn.4xprb6X2MYskuUe', 'Adewole Abdul', 92, 'sponsors/92.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:41:40', '2015-04-22 10:02:43'),
(161, 'PAR0094', '$2a$10$Zg3BOUPT0vG8S.ZvUsD5vOXsN4ZMqSAaAuPZUFr1RNUhxFa3IMo.2', 'kushimo olakunle', 94, 'sponsors/94.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 01:43:36', '2015-04-22 10:02:43'),
(162, 'PAR0095', '$2a$10$OzUInkSG87CeFSAOL.MKsOz5EpauZEsBv2UzGhhFjp8823n78uR8C', 'Sam-Micheal Azibabhom', 95, 'sponsors/95.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:43:46', '2015-04-22 10:02:43'),
(163, 'PAR0096', '$2a$10$fvSj0EbblC/mH765moeFLuHjjG3BxLcVE3waVCucMIgeDkGQmJ9A2', 'ajibode adesoji', 96, 'sponsors/96.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:44:21', '2015-04-22 10:02:43'),
(164, 'PAR0097', '$2a$10$qz0lYSqmQunVXvZg61OkLe/U9rwO9/AAQo9FFXQc4XijJDCh/NECS', 'Bagou Ayibatare', 97, 'sponsors/97.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:44:58', '2015-04-22 10:02:43'),
(165, 'PAR0098', '$2a$10$w9HSU.xITlExLo8O4qEh7u0B1iWfSA.iMCk3gAxgJnJPChyiAWOdK', 'faloye omolade', 98, 'sponsors/98.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:45:33', '2015-04-22 10:02:43'),
(167, 'PAR0100', '$2a$10$dFl1jG8ISkochVQaaSbyF.9PyrdBGc2aF88owalns6qU9S.5kwuGG', 'Isikpi Nike', 100, 'sponsors/100.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 01:47:14', '2015-04-22 10:02:43'),
(168, 'PAR0101', '$2a$10$pq5lgs/4X6XkWZzm7wEjTO8T3GsunclBYI95xp1sgVDxVMOGUsPcm', 'orhiunu lina', 101, 'sponsors/101.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:47:23', '2015-04-22 10:02:43'),
(169, 'PAR0102', '$2a$10$zyRYDcjf1bdkZIvAwdjNcu/ycZMvzAflGqbxQMChYct7r/2ISchQW', 'imasuen o.o', 102, 'sponsors/102.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:48:37', '2015-04-22 10:02:43'),
(170, 'PAR0103', '$2a$10$FSXfxBZ4FH0kdcqSfy22geJ9C8C00ZyhzhqhSf/L6mnfCHGBgQhSi', 'Momoh Muhsin', 103, 'sponsors/103.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-24 01:49:33', '2015-04-22 10:02:43'),
(171, 'PAR0104', '$2a$10$o0NLb4Xdyt3KRmiL/.1HUuhjv2v4ZH9rVRLXHfgxqtvtQLhg.l4z.', 'ishola yusuf', 104, 'sponsors/104.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:49:53', '2015-04-22 10:02:43'),
(172, 'PAR0105', '$2a$10$eDA.pZfY7/l04FFSs0p2jukeA5RLoG8h2il3r4XhbCZTMhSh2r/3m', 'Mbaegbu Norbert', 105, 'sponsors/105.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 01:51:28', '2015-04-22 10:02:43'),
(173, 'PAR0106', '$2a$10$hXkcLzng8o8BmQBIXyclCeBfI0OFOVTYNgDl86mVjMTJ2IGpyvB0W', 'madueke Joseph', 106, 'sponsors/106.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:51:34', '2015-04-22 10:02:43'),
(174, 'PAR0107', '$2a$10$pZCd/TlAD9IMDm/BQQmVwOj/kmVYVJE65eh5H0Vq41BzQib3fs2UO', 'odufuwa ayodele', 107, 'sponsors/107.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:54:29', '2015-04-22 10:02:43'),
(175, 'PAR0108', '$2a$10$weUPZchU9.PBbpmvOzONLuRUDCkw8AAe.dHhvh23mjgpX54.g45N2', 'olaniyan p.a', 108, 'sponsors/108.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 01:56:51', '2015-04-22 10:02:43'),
(176, 'PAR0109', '$2a$10$cgP4OW6gblQYQ25qoV6w8.Xdi/e090w1/G1ev5lBZ.CwzBqEGlv32', 'olory Matthew', 109, 'sponsors/109.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 02:00:01', '2015-04-22 10:02:43'),
(177, 'PAR0110', '$2a$10$EjeEG936xQLnDuNkbxUZDOye/vUP5SmZqyi4C5Nph/VDgQPznBPcW', 'Tobiah Emmanuel', 110, 'sponsors/110.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-24 02:00:32', '2015-04-22 10:02:43'),
(178, 'PAR0111', '$2a$10$pl5Iucj6/o98PaRx/2Lyl.oDm8gtvWPn5XLVz5sZpkLZl80jeN5cu', 'olory Matthew', 111, 'sponsors/111.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 02:01:04', '2015-04-22 10:02:43'),
(179, 'PAR0112', '$2a$10$FNpVNSB.8hfqVUsCbvGOJOvR3XLX6qsN8uUg16F124lfBPpazjCVC', 'oneh Matthew', 112, 'sponsors/112.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 02:06:06', '2015-04-22 10:02:43'),
(180, 'PAR0113', '$2a$10$JNEdJWv1S3e3YodaS5dGJu3F7UB0OjIZ7Ywomy25KyTGNU5fGYy6i', 'Oke Isiaka', 113, 'sponsors/113.jpg', 1, 'PAR_USERS', 1, 44, '2015-03-24 02:11:48', '2015-04-22 10:02:43'),
(181, 'PAR0114', '$2a$10$K4pxzExQyKOVNr0L/p8.8O3H/qA.TYs2eQheQXdYRuCUsh3nP5ipe', 'onung nkereuwem', 114, 'sponsors/114.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 02:12:04', '2015-04-22 10:02:43'),
(182, 'PAR0115', '$2a$10$S4197J/8y2fq.BtJkiQGL.iEU4lCPQibaJAEfhS.3TteMyibLn/Y6', 'osadolor Kingsley', 115, 'sponsors/115.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 02:15:02', '2015-04-22 10:02:43'),
(183, 'PAR0116', '$2a$10$EjdSMs/zg1kA/c26Arf6KeQ93fPm7TNbVUP0FsC4C7XVLO9/3TmUC', 'ATABULE FAITH', 116, 'sponsors/116.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:18:25', '2015-04-22 10:02:43'),
(184, 'PAR0117', '$2a$10$GTPIhm4VZXKWtOkfZEqKcOMEVUel0h0Pfj6N/vwkBbGdsWbIkxZAi', 'KUSHIMOH OLAMIDE', 117, 'sponsors/117.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:19:05', '2015-04-22 10:02:43'),
(186, 'PAR0119', '$2a$10$D6.ojGOtHHamVIBVWC7c4urakks8EdeMk/R3M8b9HKnBDAB3qajSC', 'OGUNDIMU MOTUNRAYO', 119, 'sponsors/119.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:21:29', '2015-04-22 10:02:43'),
(187, 'PAR0120', '$2a$10$BmY0LIYpq3VlILtRKNFyTeUXbbSLvPCQDjBkVMzmdJvIGRzwMph6W', 'BUHARI-ABDULLAHI HAUWA', 120, 'sponsors/120.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:22:41', '2015-04-22 10:02:43'),
(188, 'PAR0121', '$2a$10$BGNCzKaavb019DbO7HjioewXo7GPq8FOIwKPy/SM5cMooLCyqz5qy', 'Faloye Ayomide', 121, 'sponsors/121.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-24 02:22:59', '2015-04-22 10:02:43'),
(189, 'PAR0122', '$2a$10$qnHYpA09lyevUx9CRM.ccu1sYjBQRaaJXKc1MKIIyiJ/VD0UEZEE2', 'LAWAL ENIOLA', 122, 'sponsors/122.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:24:32', '2015-04-22 10:02:43'),
(190, 'PAR0123', '$2a$10$tvpp/xerb743VO8nWdvUCu1npZ8lyVzpk51mm4/kbP8mo74IyCndW', 'Asubiaro Tomisin', 123, 'sponsors/123.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 02:24:51', '2015-04-22 10:02:43'),
(191, 'PAR0124', '$2a$10$o2WjHjv075Nn8zwIt7t0TeXkqSGksPBlB3Y8V9o/H3MXB/xsW9vMe', 'ibeke okey', 124, 'sponsors/124.jpg', 1, 'PAR_USERS', 1, 65, '2015-03-24 02:25:03', '2015-04-22 10:02:43'),
(192, 'PAR0125', '$2a$10$yzdFj3K/HSqV06rZR7dld.qDErfcze.6YqTF6oFarLTVwXnZuE5BO', 'ITSEUWA EMILY', 125, 'sponsors/125.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:26:10', '2015-04-22 10:02:43'),
(193, 'PAR0126', '$2a$10$p7cTR.Thx/DR5s9C1eumJO5g5j/8w2n9OLEsz2jH7Pb4VXhN4afu2', 'OSHOBU OLUWAFUNMILAYO', 126, 'sponsors/126.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:27:47', '2015-04-22 10:02:43'),
(194, 'PAR0127', '$2a$10$EIPvex.v34lChOSJ6Iid1ush0rj3uyCPgqE177SJeqW/57R4MBheW', 'SANNI OLUWASEUN', 127, 'sponsors/127.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:28:52', '2015-04-22 10:02:43'),
(195, 'PAR0128', '$2a$10$zyZS.rpeX.pQGGiBkUJ0n.Q.I9YfL3gkGb0Uc/0u3vEdYYpxGFqhC', 'ONYEMAECHI JENNIFER', 128, 'sponsors/128.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:29:56', '2015-04-22 10:02:43'),
(196, 'PAR0129', '$2a$10$ppdMTmPAXgcjHKmDCeHaueCb/o8rkLpjYZcKUvZiCUi8tQpSgBnvK', 'ERIVWODE  RUKEVWE', 129, 'sponsors/129.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:31:00', '2015-04-22 10:02:43'),
(197, 'PAR0130', '$2a$10$8o/M6lMtiTFL30HaVYy9KOJeAdZZ3716JeWyU1YPtYL7wBpJyhznC', 'LAWAL HABEEBAT', 130, 'sponsors/130.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:32:03', '2015-04-22 10:02:43'),
(198, 'PAR0131', '$2a$10$xjdasZKqjWsABzuz5t5Q6uG2jWXI17kLFFFjSw398Ij31m92xCy6u', 'POPOOLA IBUKUN', 131, 'sponsors/131.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:32:59', '2015-04-22 10:02:43'),
(199, 'PAR0132', '$2a$10$j/VKZUHJWCzaKhyOwFQPxe.8MwuaaCRcxQopl1YVwcB9kticAqf0O', 'NOIKI OLUWATOMIWA', 132, 'sponsors/132.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:33:52', '2015-04-22 10:02:43'),
(200, 'PAR0133', '$2a$10$oWR1k26aLR7u2CxE24UyWOYwny6EDG9R634I.diW.YYYZX.P.Drs.', 'EZEJELUE SOMKENE', 133, 'sponsors/133.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 02:34:55', '2015-04-22 10:02:43'),
(201, 'PAR0134', '$2a$10$YPAxloswhPJ3V1qTC/44L.oz7mSyL42V1iCr7jHBkPUGfKID.7Z/u', 'Faluade Kayode', 134, 'sponsors/134.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 02:48:18', '2015-04-22 10:02:43'),
(202, 'PAR0135', '$2a$10$Q7m0zf8r4rRShAA7r.zYtuXvW3VyiyMNIwRMT9FVPvioPziO2uKNy', 'Hamman-Obel Ogheneyoma', 135, 'sponsors/135.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-24 02:48:23', '2015-04-22 10:02:43'),
(203, 'PAR0136', '$2a$10$HQ8W7TW4IOGvWJ8ZC50o7.qMmoaT/vbQItmiv1Qv40Xvd/saBT/X6', 'Akintola Ibrahim', 136, 'sponsors/136.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 02:50:38', '2015-04-22 10:02:43'),
(204, 'PAR0137', '$2a$10$E6upQkf7XSv8ma0q7O5vcey/5odeomILYkKofV0KT8SGf5I3LhfDG', 'Hassan Adetunji', 137, 'sponsors/137.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 02:52:09', '2015-04-22 10:02:43'),
(205, 'PAR0138', '$2a$10$7Kq2ZvIH.MZxZzTQ8IDE7OL4FrD.XMVS2.PySOGPdwoxcseWodexq', 'Okesina Victor', 138, 'sponsors/138.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 02:53:42', '2015-04-22 10:02:43'),
(206, 'PAR0139', '$2a$10$1AxewdlI3odh6RnYwTFOuOAopx1jAmIv.3BsBLOKIHxL89kYPTc4u', 'Adeniyi Adeyinka', 139, 'sponsors/139.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 02:54:59', '2015-04-22 10:02:43'),
(208, 'PAR0141', '$2a$10$5fbmq1whWDWC0Fou0CAbbO1T05xVpQSR.JTffs0gbP5uKwCl/gY.e', 'Adesina Adekunle', 141, 'sponsors/141.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 02:59:11', '2015-04-22 10:02:43'),
(209, 'PAR0142', '$2a$10$60ENXEK7lcVrW1tH6hhGzO9026cv8swqKvCCxAmqO7bj1o9ZIhpKa', 'Agunbiade Olukayode', 142, 'sponsors/142.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 03:03:38', '2015-04-22 10:02:43'),
(210, 'PAR0143', '$2a$10$GtC0jpByu0RRO4YY2xsujOryo9JQZnyWPxReYxerRDJqZlJ1CexW2', 'Chinda Hope', 143, 'sponsors/143.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 03:04:50', '2015-04-22 10:02:43'),
(211, 'PAR0144', '$2a$10$hm0HvdFgzuXwKt.HIrqdzOnsKh7potbM5c9v.WVgC3hJj3ukZnK2K', 'Samson Olufemi', 144, 'sponsors/144.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 03:06:43', '2015-04-22 10:02:43'),
(212, 'PAR0145', '$2a$10$mvfjQxP7P0y7opadT.9kIOJJEHTFRXszX9Gv3nTm4.azgdTAPAZTS', 'ABDOU AMOUDATH', 145, 'sponsors/145.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 03:08:15', '2015-04-22 10:02:43'),
(213, 'PAR0146', '$2a$10$EzULmYjBj8sz..cvefhpc.LAG0mrmSPr/jtRnb2QnBNs6kVpx3cSe', 'BAKRE BABAJIDE', 146, 'sponsors/146.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:13:57', '2015-04-22 10:02:43'),
(214, 'PAR0147', '$2a$10$HdWzvGhFHT87HWZmB5SVre3BNaVFlf/0o3TtCyDL1Q6q6b5jZQ/Ae', 'chiejile Williams', 147, 'sponsors/147.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:14:55', '2015-04-22 10:02:43'),
(215, 'PAR0148', '$2a$10$KVBBQ3c1GZy7Yt5Py5khTulI2FZN0QIi3hXlXqmpCX/30c.UTz2U6', 'Lawal Sunkanmi', 148, 'sponsors/148.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:15:30', '2015-04-22 10:02:43'),
(216, 'PAR0149', '$2a$10$aYeBYMDr6W9YNLtPb8MKVuJYvvQcQzUxRfpTUmau37trp3awKZ3ki', 'Nwogu Victor', 149, 'sponsors/149.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:16:18', '2015-04-22 10:02:43'),
(217, 'PAR0150', '$2a$10$H8c/VQykuxiTmJM8i1SaVOUKStVPTD9cBSfQckBnoYrBX/eH16qDu', 'Okeke  Chigozie', 150, 'sponsors/150.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:16:56', '2015-04-22 10:02:43'),
(218, 'PAR0151', '$2a$10$rq/T.BQFzUcSivRV7YvsLuY0szpb6bk0WNW74YtQYQ4CCv2x/xoxO', 'Ogunbanjo Timilehin', 151, 'sponsors/151.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:17:35', '2015-04-22 10:02:43'),
(219, 'PAR0152', '$2a$10$nbTy4yRwqkAgeMSqFtYX/OKt91NIK87HMpbLHQEjQlOq1ZdmQd8pK', 'Onwuchelu  Christian', 152, 'sponsors/152.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:18:41', '2015-04-22 10:02:43'),
(220, 'PAR0153', '$2a$10$n/bwFMlCFpNkfn2lk8SPruAwxXzbOaTIpQYCFBUgs4xvT5SK4zP7G', 'Soyebi Oluwaseun', 153, 'sponsors/153.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:19:19', '2015-04-22 10:02:43'),
(221, 'PAR0154', '$2a$10$Sk.g/RlWVMG5FsYRsSawd.8COYO..MX2pAHNBNgUIVACzD0x7947O', 'Uduji-Emenike Chibueze', 154, 'sponsors/154.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:20:06', '2015-04-22 10:02:43'),
(222, 'PAR0155', '$2a$10$Mdt4oBahOR0GJq4wMswBbuBjj5RQntYIrUjjeFuW7Vkk1FQRL2Vyy', 'Olatunbosun Olaoluwa', 155, 'sponsors/155.jpg', 1, 'PAR_USERS', 1, 0, '2015-03-24 03:28:01', '2015-04-22 10:02:43'),
(223, 'PAR0156', '$2a$10$Vh.sO5r6PUM/kgHvq7zXWuDmY1krdjPOLYA8U0HcRUa/ZpWDiOTwS', 'Ikpi-Iyam Felix', 156, 'sponsors/156.jpg', 1, 'PAR_USERS', 1, 13, '2015-03-24 03:21:53', '2015-04-22 10:02:43'),
(225, 'PAR0158', '$2a$10$yy0EYgDGXEZrkpZjcwnBxODBCUNJY8WrSG.8ntUVU3ScGRZuO9vom', 'KAZEEM OLAWALE', 158, 'sponsors/158.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 03:38:18', '2015-04-22 10:02:43'),
(226, 'PAR0159', '$2a$10$t5TDN7QIGW4BLBwc8h4rq.EttW7Nkg3Lc7wwOG83Ghy5U74uyw6tS', 'UGOCHUKWU CHRISTINA', 159, 'sponsors/159.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 03:44:20', '2015-04-22 10:02:43'),
(227, 'PAR0160', '$2a$10$FwZuZ.GP154/j5HAkPBdweq/1nRkQ/KypiUIVCuvoNv08L3BAqlHa', 'OJUDU BABAFEMI ', 160, 'sponsors/160.jpg', 1, 'PAR_USERS', 1, 60, '2015-03-24 03:52:35', '2015-04-22 10:02:43'),
(228, 'PAR0161', '$2a$10$HPlCdZ/YwpKSVu9cCOlZ6uBByWL7YNYe.OxslM0YCXYmiarU5rSwu', 'Afolabi wuraola', 161, 'sponsors/161.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 03:55:54', '2015-04-22 10:02:43'),
(229, 'PAR0162', '$2a$10$DAVP69pUBeJtbL/8tOZhCui/SHMYYYfrNOICEm2mEgl.QW1fAvdYe', 'Angel EMMANUEL', 162, 'sponsors/162.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 03:56:54', '2015-04-22 10:02:43'),
(230, 'PAR0163', '$2a$10$dopc6euJZvS2wmcRn50l6e1wxBrPhwPjBMlkaPxs9savz39CdzRze', 'Ikpi-Iyam Irene', 163, 'sponsors/163.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 03:58:14', '2015-04-22 10:02:43'),
(231, 'PAR0164', '$2a$10$S9Lpbi5cgxro3L3IssjQRODo6kn1bpVlsELHIym7FsiEsO0nDlPce', 'Johnson Precious', 164, 'sponsors/164.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 03:59:31', '2015-04-22 10:02:43'),
(232, 'PAR0165', '$2a$10$7Qfq7BCIG7vGYFSOncnIrOeDYpmy.OeKXwxNZ2/YiNB7r1/zZxPpK', 'Okey-Ezealah Viola', 165, 'sponsors/165.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 04:02:07', '2015-04-22 10:02:43'),
(233, 'PAR0166', '$2a$10$ECsApzbVrSwhZ5MdwuTCc.v633FQ1ksYqMVJ1QvEMHykLzjA89x3K', 'Oshobu Yemisi', 166, 'sponsors/166.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 04:03:30', '2015-04-22 10:02:43'),
(235, 'PAR0168', '$2a$10$Ho42ynPloOKzfaA/Qa2RJ.sEKtDkkfkOO3qiDGfYAWXTKh9F2wztS', 'Sobowale Anike', 168, 'sponsors/168.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 04:05:42', '2015-04-22 10:02:43'),
(236, 'PAR0169', '$2a$10$W34NS77Sgw2wl89lAkjFNu5Fsw7LJPITUkBWwExskbGLf/BFqlg3a', 'Yahaya Mariam', 169, 'sponsors/169.jpg', 1, 'PAR_USERS', 1, 23, '2015-03-24 04:06:59', '2015-04-22 10:02:43'),
(237, 'PAR0170', '$2a$10$fMg7DtvMRnVX9zGIM0P9kOQN0W8q8sIAKw5kXUpSAyLZTv11sHx9C', 'DANDEKAR RAJEEV', 170, 'sponsors/170.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:09:02', '2015-04-22 10:02:43'),
(238, 'PAR0171', '$2a$10$/ea4uQmREu2X8GVOf5RW1eJFUZ3KCLFlIeXv2UYtfyXoutzlLm4uy', 'ONONAEKE KENNEDY', 171, 'sponsors/171.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:10:28', '2015-04-22 10:02:43'),
(239, 'PAR0172', '$2a$10$H1m6a2Pkuvz3cuCmEerhHOqjshbClsj293SnzRJXXD35uDMlv3/aa', 'ANAGBE PETER PAUL', 172, 'sponsors/172.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:12:03', '2015-04-22 10:02:43'),
(240, 'PAR0173', '$2a$10$etnFTQG38Ikpmr4EcREtAepkbf4uvu7cdGYtkVhKUE/MRHcwWzr3G', 'ALAYANDE OLALEKAN', 173, 'sponsors/173.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:13:06', '2015-04-22 10:02:43'),
(241, 'PAR0174', '$2a$10$64lmlUC5uCqGrgn/gDlKOujGTim8Y.J0yuUV9mlS.pl2qlbdEdTUm', 'OYENIRAN MUFTAU', 174, 'sponsors/174.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:13:52', '2015-04-22 10:02:43'),
(245, 'PAR0178', '$2a$10$/N4DPTXFKnGO5pUHQeaD4.hR7P4pgkpJLPVwSn2lUwNdAyqUS4pqW', 'Olukokun Adediran', 178, 'sponsors/178.jpg', 1, 'PAR_USERS', 1, 50, '2015-03-24 04:24:32', '2015-04-22 10:02:43'),
(246, 'PAR0179', '$2a$10$/7MU61LqYGEJ.LCIAw1VpOQ2tQHWCPAsM0O/jcx4SkBrBa4EIL7f.', 'AKINTELU ADEBAYO', 179, 'sponsors/179.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:27:11', '2015-04-22 10:02:43'),
(247, 'PAR0180', '$2a$10$iPp.U55rSExHjpWvzyZ3xuTU8VwiFPdru1EoiQ9G88.yJavA0RYBi', 'LAWRENCE ADEPOJU', 180, 'sponsors/180.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:35:02', '2015-04-22 10:02:43'),
(248, 'PAR0181', '$2a$10$VkZAt.cBwUpFedVHv8bEkeoGIzFX7ylYYL7zf0mV6J3UTQNbVmx/e', 'ABIOLA HAFEEZ', 181, 'sponsors/181.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:35:06', '2015-04-22 10:02:43'),
(249, 'PAR0182', '$2a$10$wi/VdYOnR2dDm/zoh7SVL.vRSXadiJ4r/k1z4MtXa3Gh8Zn4rXlPO', 'OLADAPO ADEOSUN', 182, 'sponsors/182.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:36:06', '2015-04-22 10:02:43'),
(250, 'PAR0183', '$2a$10$6Yvw6VfMG/xrZQp6uylpz.WFaOZLyVsoTzsG5YVeDRR/97G8hhc6G', 'ADENIYI ABDULSALAM ', 183, 'sponsors/183.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:37:02', '2015-04-22 10:02:43'),
(251, 'PAR0184', '$2a$10$qoxLp/shPQoRe9dIbM.dR.m0h4GdFJHP54izb.8bYuuFl3HYzOwmu', 'UBANDOMA BELLO', 184, 'sponsors/184.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:37:47', '2015-04-22 10:02:43'),
(252, 'PAR0185', '$2a$10$mrm/0GtvRTQ5rWwwQTjfv.0kx2ZekC6IeKRT8EoNqPiF4w5phKatC', 'AJIBOLA ISLAM', 185, 'sponsors/185.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:38:16', '2015-04-22 10:02:43'),
(253, 'PAR0186', '$2a$10$MQzPl3k3yittjLztCYGGLOrNrPSWwzmazqiMMZ2fmpWRit0mE9j6C', 'BAKARE OLUDAYO', 186, 'sponsors/186.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:39:18', '2015-04-22 10:02:43'),
(255, 'PAR0188', '$2a$10$Y/tEk4RCELp6spmiiOMzB.zVUzxoST8g8omiFehWgeH0MiQGzpQ0G', 'BELLO  AYOTUNDE', 188, 'sponsors/188.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:40:26', '2015-04-22 10:02:43'),
(256, 'PAR0189', '$2a$10$y0V3leiq6Dd9znoaBIAEIuH69nF73WzVGperZCxKULdiQ56hu7nOK', 'EMMANUEL OBINNA', 189, 'sponsors/189.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:41:32', '2015-04-22 10:02:43'),
(257, 'PAR0190', '$2a$10$jUN5/gCyUq.e18kNRYa4EeNc9QC6VyjcVDljTgAgNc1ys8kwH5/GS', 'FOLORUNSO IYIOLA', 190, 'sponsors/190.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:43:05', '2015-04-22 10:02:43'),
(258, 'PAR0191', '$2a$10$lGJtwo2LAe13yPoIZLBpuO5OWkrOY.wMo0g.TsdEzaCnvIWbyRv0.', 'IDOWU OLUWABUKUNMI', 191, 'sponsors/191.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:44:17', '2015-04-22 10:02:43'),
(259, 'PAR0192', '$2a$10$UC7FOBVHZMYLOMdb7cPXaukd8Xd4hTu5EpcH0LaskRqFaXaYUAUu2', 'NIKORO OMAGBITSE', 192, 'sponsors/192.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:45:18', '2015-04-22 10:02:43'),
(260, 'PAR0193', '$2a$10$MiM1lm7m4Nyo6dfDiz3hSOvHUtTQ1PrEWtmD3HVxaimkQe9hFzk7y', 'FAYOMI I', 193, 'sponsors/193.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:45:48', '2015-04-22 10:02:43'),
(261, 'PAR0194', '$2a$10$cFTcRqRAB8gwf3/TkXXJjuz04Fzs5/N0DZNEMZ/btaRC8Q0KDN31q', 'OBRIBAI SAMSON', 194, 'sponsors/194.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:46:23', '2015-04-22 10:02:43'),
(262, 'PAR0195', '$2a$10$BPYyZlXUo5R06osahnXqzeensLyUrDbFufh5nr3GqlJb1PJRYW9XW', 'ELENDU CHURCHIL', 195, 'sponsors/195.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 04:46:53', '2015-04-22 10:02:43'),
(263, 'PAR0196', '$2a$10$vUyhA0jqfeHCUSNrXtHPVOgE8W35G9m7oysnGBY4/n98UOAOO8wce', 'OGUNDIMU  MOBOLUWADURO', 196, 'sponsors/196.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:47:24', '2015-04-22 10:02:43'),
(265, 'PAR0198', '$2a$10$MxhtoRQLI73YXnFILngvnuUQbanp0e5nIAMSK6x5ipnjcwkYBr/tS', 'OGUNEKO AYOOLA', 198, 'sponsors/198.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:48:52', '2015-04-22 10:02:43'),
(266, 'PAR0199', '$2a$10$5ucb0CJKBruIuT5NAxUNr.XREhyfibfgGfniQCiqfQfy0KzXC6bma', 'OKOYE  PAUL', 199, 'sponsors/199.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:49:29', '2015-04-22 10:02:43'),
(267, 'PAR0200', '$2a$10$9qHyVM7Id3mQNDYrzt4GRebAruvc0XQdTb.cXkkCnTDLF6m8hnHSm', 'OKPARA NATHANIEL', 200, 'sponsors/200.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:50:29', '2015-04-22 10:02:43'),
(268, 'PAR0201', '$2a$10$1rd.K6ZueEl75TETB0sNKukNts3CAYy7ykg80zzRt7s2vwVF6Kebe', 'SOWOLE AYOTOMI ', 201, 'sponsors/201.jpg', 1, 'PAR_USERS', 1, 16, '2015-03-24 04:51:28', '2015-04-22 10:02:43'),
(271, 'PAR0204', '$2a$10$bBtSfF4MjtZkrk4Bf2FkFuWODp4xDzPAVbmI9rqt8B4LHA8zpk/Ry', 'SOGE ABAYOMI', 204, 'sponsors/204.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 06:55:11', '2015-03-24 17:55:11'),
(272, 'PAR0205', '$2a$10$9qQXjf7kGzu2zPSWMGSqyeZlM4w53agQKnhgnKq95wGMR9h43CBOi', 'RAJI HABEEB', 205, 'sponsors/205.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 06:58:45', '2015-03-24 17:58:45'),
(273, 'PAR0206', '$2a$10$zqDB3qaqRb6nJciA2Nu1NOgVYzYWZV/3TbCttaSNPXpeBVjraPDlO', 'OSINAIKE OLANREWAJU', 206, 'sponsors/206.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 07:04:54', '2015-03-24 18:04:54'),
(274, 'PAR0207', '$2a$10$UKGPE5mgS8XjsZclmpj6we9vNEuPGIntCEdxRtntlKltvFxMqTcLW', 'AMZAT YAYA', 207, 'sponsors/207.jpg', 1, 'PAR_USERS', 1, 62, '2015-03-24 07:08:01', '2015-03-24 18:08:01'),
(275, 'PAR0208', '$2a$10$P3/6.h7eFce76NpNHdywJu3qWVxUHvmUYvTkChdIClcApiYxV9suK', 'Soge Olumuyiwa', 208, 'sponsors/208.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:12:08', '2015-04-22 10:02:43'),
(276, 'PAR0209', '$2a$10$Y4eBsQgwVLRpC4VS6bH94O0uG82zCyKs63rr0CBejFCC3s0v44zqO', 'Shadouh Hani', 209, 'sponsors/209.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:15:40', '2015-04-22 10:02:43'),
(277, 'PAR0210', '$2a$10$1BUY8hEFnsATOjK.fkQYQ.sZivGb.HOQOfcO4cvKradr/o24Ur7q6', 'Ibazebo Adeniyi', 210, 'sponsors/210.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:17:47', '2015-04-22 10:02:43'),
(278, 'PAR0211', '$2a$10$gYaq/NCiG5lWy13oyD60IOj/iLcUiWDa1X3Z/Wzc/heLD3SROD2xW', 'Ajisebutu Olusayo', 211, 'sponsors/211.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:20:41', '2015-04-22 10:02:43'),
(279, 'PAR0212', '$2a$10$Q.zupOfk0GvYDAd1bT/GV.sHOSuSQC42gbqZzaSN8s8ZEi/2elgpq', 'Oshunlola Yisa', 212, 'sponsors/212.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:21:29', '2015-04-22 10:02:43'),
(280, 'PAR0213', '$2a$10$Lfp.vxEHJ2GZCQDMsR/YsuNLsq57NV6GOthOw2S4hDSDsMSNRDMpy', 'Olaore Oludare', 213, 'sponsors/213.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:22:43', '2015-04-22 10:02:43'),
(281, 'PAR0214', '$2a$10$RMecvAnNLq8nvaiEtcOTWeNoCJWZWT.tm42pdoyLXj3xez0snIdGS', 'Olasedidun Tunde', 214, 'sponsors/214.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:26:32', '2015-04-22 10:02:43'),
(282, 'PAR0215', '$2a$10$hpUguTzlR6KqW6VjO/YRZORiul8ErCVEvbLxdqbsCK5ro5bOSy6ry', 'Adepoju Lawrence', 215, 'sponsors/215.jpg', 1, 'PAR_USERS', 1, 40, '2015-03-25 08:28:22', '2015-04-22 10:02:43'),
(283, 'PAR0216', '$2a$10$6opOVcizmAQMSsWDL7Kxt.s6k1sEgug7eaLZ/vykd7N2tGoVCDksa', 'Onwuchelu Emeka', 216, 'sponsors/216.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:13:15', '2015-04-22 10:02:43'),
(284, 'PAR0217', '$2a$10$SSlXW1RrbZD8H8nPW4/UlOFKy7gYpg.EdoRiGojJD052aPoI3ZbaS', 'Ishola Bolaji', 217, 'sponsors/217.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:19:24', '2015-04-22 10:02:43'),
(285, 'PAR0218', '$2a$10$W3hCUxlITQz1YDqPRvZ1JOx.mS/y21iSq.2S.FFYmC0hd8lKIApKm', 'Akpama Paul', 218, 'sponsors/218.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:23:02', '2015-04-22 10:02:43'),
(286, 'PAR0219', '$2a$10$ls7nNLluzYs90ByBz6et6egz6DdvKM8rzf7HruR0qGEuOGnkSnezG', 'Wikimor John', 219, 'sponsors/219.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:25:44', '2015-04-22 10:02:43'),
(287, 'PAR0220', '$2a$10$MqDH66YRr9fHp/lrh8yGO.dQKbAcZxfUc.WGy5C/tPRHO.NKacSde', 'Ziworitin Ebikabo-Owei', 220, 'sponsors/220.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:30:26', '2015-04-22 10:02:43'),
(288, 'PAR0221', '$2a$10$x5rxRkLGZFbkwh3QBTdo5.teeoiXZFQqUeZzwU9xtU31Ztd.0LSs.', 'Olumese Anthony', 221, 'sponsors/221.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:31:19', '2015-04-22 10:02:43'),
(289, 'PAR0222', '$2a$10$1YJTCGibDbdzZbiwyNp2l.EoNHG.Sz/Y.xnNBt7gYWW58dtYUWjza', 'Markbere Abraham', 222, 'sponsors/222.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:33:05', '2015-04-22 10:02:43');
INSERT INTO `users` (`user_id`, `username`, `password`, `display_name`, `type_id`, `image_url`, `user_role_id`, `group_alias`, `status_id`, `created_by`, `created_at`, `updated_at`) VALUES
(290, 'PAR0223', '$2a$10$2qMCIIWd54.f6rp.nYkeVeb.2qfqi8NHq42IEz.b6UVYhkakR488C', 'Okunbor Ifeanyi', 223, 'sponsors/223.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:34:37', '2015-04-22 10:02:43'),
(291, 'PAR0224', '$2a$10$KbkBI8BA9gBKxrl8MYqQ0.G8k9Aq76xNxoI/ygGcVxT0JYbzYELz6', 'Osinbanjo Oluwafemi', 224, 'sponsors/224.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:35:20', '2015-04-22 10:02:43'),
(292, 'PAR0225', '$2a$10$N2wi0PDK9VSIXwH/WNg2vu7vIz6.RAQZPa10S4UDlMSXDbrTMl8jq', 'Awolaja Adekunle', 225, 'sponsors/225.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:35:58', '2015-04-22 10:02:43'),
(293, 'PAR0226', '$2a$10$CnIMG9ybxYMMFbwvWfESlujdfsb8aKQTvwzO1ID/SFuoOabr9JOyC', 'Abdou Fatou', 226, 'sponsors/226.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:37:01', '2015-04-22 10:02:43'),
(294, 'PAR0227', '$2a$10$gr9MqojWlIp1ca21oFDD.ueWiUXa4SRggSszXIwwXdJSuza6cnS8m', 'Emmanuel Offodile', 227, 'sponsors/227.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:38:02', '2015-04-22 10:02:43'),
(295, 'PAR0228', '$2a$10$iouU5e9sizud24gDdhvQg.p3W8aATPwP/O3Y92/GbvsNx7dBKoEpK', 'Ohadike Michael', 228, 'sponsors/228.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:38:40', '2015-04-22 10:02:43'),
(296, 'PAR0229', '$2a$10$9FwzZc6tdg/WzdLzqBBoPOAxCllDJ0nyJ1afymIhgo5XSVagaGHKC', 'Owhonda Okechukwu', 229, 'sponsors/229.jpg', 1, 'PAR_USERS', 1, 38, '2015-03-25 09:39:32', '2015-04-22 10:02:43'),
(297, 'PAR0230', '$2a$10$2Bh1Nq/cRNVx8XbZRgGnjObfP5LCi7d5CUcvpxsCMYWOI6t1txdhe', 'Eldine Layefa', 230, 'sponsors/230.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:41:57', '2015-04-22 10:02:43'),
(298, 'PAR0231', '$2a$10$HL2rzezWQve5pKbotpDAZ.NTXJZCvUyclweFG6OXzzSIkvP8dUn0i', 'Simolings Simolings', 231, 'sponsors/231.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:45:43', '2015-04-22 10:02:43'),
(299, 'PAR0232', '$2a$10$PvUwOw4KbXjA.Zh8zxqiEOHrRM4SgCB0q30NX/qJRXJTU409mijz2', 'Anagbe Peter', 232, 'sponsors/232.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 09:51:13', '2015-04-22 10:02:43'),
(300, 'PAR0233', '$2a$10$8DRwj5etmZym3YnYHJ3KleJI3XHlUfkG08HkPDMxvf3.PeZKbJdzK', 'Akinola Afolabi', 233, 'sponsors/233.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 09:51:59', '2015-04-22 10:02:43'),
(301, 'PAR0234', '$2a$10$3jwKFWXQJtpJMyFGCog6ZevfrC5Pl5gWVqOl06BldwVJ7RCAnKboK', 'Shadrack Amos', 234, 'sponsors/234.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 09:53:48', '2015-04-22 10:02:43'),
(302, 'PAR0235', '$2a$10$LGeEj7HK3RSz42yZYHEkbOsTvs7XsZitox0BefuVjB7iEVb.WmZzK', 'Gbadebo Adebisi', 235, 'sponsors/235.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 09:54:00', '2015-04-22 10:02:43'),
(303, 'PAR0236', '$2a$10$bT0FoDjLONHhxjuxZUHgd.5eTbON./3GCYm0hK0MF7vA0Dgn1vFiy', 'Ogundeyi Najeem', 236, 'sponsors/236.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 09:55:34', '2015-04-22 10:02:43'),
(304, 'PAR0237', '$2a$10$uNC1anL4SttSqcHpZdxbuefMRCjcG4SP9PFpywl6OdsQjz4xcc9H6', 'Ogunbona Ismael', 237, 'sponsors/237.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 09:57:57', '2015-04-22 10:02:43'),
(305, 'PAR0238', '$2a$10$Zb4PM1pjf2SB/tgJhrGRHezXEJaEAqqVd3KUEoLRqiOMboP2MJRsO', 'Olukokun Adeniran', 238, 'sponsors/238.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 10:04:05', '2015-04-22 10:02:43'),
(306, 'PAR0239', '$2a$10$S/T9m46SY8c5ROCLULie1eRmNMzVAD5YbQ8KUkMPRq1DqbSJEy3HW', 'Ojo Oluwagbenga', 239, 'sponsors/239.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 10:04:48', '2015-04-22 10:02:43'),
(307, 'PAR0240', '$2a$10$pbr8nBNMH4fS6ximHMVUnuMsKHUPOuV9m.FwxjFOefq.6uuow9ofC', 'Raji Habeeb', 240, 'sponsors/240.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 10:05:33', '2015-04-22 10:02:43'),
(308, 'PAR0241', '$2a$10$D6/ZHNmFQUEJPh37ZIhBduiEWLTvP1OULNkD/Gx98i74SwGyy8kR.', 'Adeola Rotimi', 241, 'sponsors/241.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 10:06:21', '2015-04-22 10:02:43'),
(309, 'PAR0242', '$2a$10$yYRs.M8QUfcKURyuowA2/e3bMFxOb1zcVmbeTQbVTEnkSmpSN2UvG', 'Oyedeji James', 242, 'sponsors/242.jpg', 1, 'PAR_USERS', 1, 54, '2015-03-25 10:07:28', '2015-04-22 10:02:43'),
(310, 'PAR0243', '$2a$10$n7v2HSrw5T1FEVz0DrOJfOZE6fD1T17FEMAQbIjfDgBTrpRahLphO', 'Promise Joel', 243, 'sponsors/243.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 10:08:33', '2015-04-22 10:02:43'),
(311, 'PAR0244', '$2a$10$skwKN27q1h4KlcUycIREG.ByNl6XSuoucl7nxeJhYxPjkhZ3OZMWC', 'Agadah Ebiye', 244, 'sponsors/244.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 10:35:52', '2015-04-22 10:02:43'),
(313, 'PAR0246', '$2a$10$W.ucvumVc7s0IQZpXvPaveMJAqTbwKbXDWk5135JdgTvx4IgeCNdu', 'Jesumienpreder Ayere', 246, 'sponsors/246.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 10:41:43', '2015-04-22 10:02:43'),
(314, 'PAR0247', '$2a$10$itBTbsNxuwPL9M.AzwfJXeYjTe9qgUVKTMom8/g/sOVvWgpCsGVU6', 'DANIEL Emmanuel', 247, 'sponsors/247.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-25 11:35:25', '2015-04-22 10:02:43'),
(315, 'STF0066', '$2a$10$ilsbwTs5VOLIXvzod/RFFOHCiyJpgYQJQ9nVBZTi5zV3.FXLEDAP.', 'ZIWORITIN Ebikabo-Owei', 66, 'employees/66.jpg', 4, 'ICT_USERS', 1, 43, '2015-03-25 11:46:52', '2015-03-26 07:59:53'),
(316, 'PAR0248', '$2a$10$IJNkNhejJlO.ycPqPD29IupJsFllz64uam7vqf99G2Xd8L57W56t.', 'Akunwa Glory', 248, 'sponsors/248.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 12:44:02', '2015-04-22 10:02:43'),
(317, 'PAR0249', '$2a$10$70HBi/QdbC7eNC.L1OUPleJEXNMeTU7dmowPRS9V.fVLMoU4UlQQC', 'Anokwuru Obioma', 249, 'sponsors/249.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 12:46:14', '2015-04-22 10:02:43'),
(319, 'PAR0251', '$2a$10$FjR4zrz/x4vSY/k.1E.TP.TRM5GVoR4DUdzSaOcOuMTfK2i0/H6au', 'Bello Garba', 251, 'sponsors/251.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 12:50:12', '2015-04-22 10:02:43'),
(320, 'PAR0252', '$2a$10$KV3cI4yTTOpLMfj1HS8coelJCjwXAWmbvUTzKaPq9fiGE9eChZHma', 'DADINSON-OGBOGBO  David', 252, 'sponsors/252.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 12:51:49', '2015-04-22 10:02:43'),
(321, 'PAR0253', '$2a$10$Umw.MCLgH38AtrEImEL96uwn0mzZ11fhiaFfhZM.EG.P7dDPR3.Ri', 'Bayelsa Guardian', 253, 'sponsors/253.jpg', 1, 'PAR_USERS', 1, 46, '2015-03-25 01:27:30', '2015-04-22 10:02:43'),
(322, 'PAR0254', '$2a$10$eD0v4OP98dz8TrTzBFhjmOTyxaoA6iFsBpdnEKSF9NvoGMLdMz9TC', 'NWOKEKE FAVOUR', 254, 'sponsors/254.jpg', 1, 'PAR_USERS', 1, 46, '2015-03-25 01:31:40', '2015-03-25 12:31:40'),
(324, 'PAR0256', '$2a$10$UQPfQoLX4f5cFT4Q4dZyGeGF3D9FDaOPx5T45AE20JJZSDkSOYW6O', 'DADINSON-OGBOGBO  David', 256, 'sponsors/256.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 02:01:23', '2015-04-22 10:02:43'),
(325, 'PAR0257', '$2a$10$tkUvTFM5ZWM3fFwh5htzI.VMv.3JqGeXifI9y84hCBJ8QuAa0OxHe', 'DAPPAH  Owabomate', 257, 'sponsors/257.jpg', 1, 'PAR_USERS', 1, 42, '2015-03-25 02:05:07', '2015-04-22 10:02:43'),
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
(342, 'PAR0273', '$2a$10$8i9ekrmYYX0PnmmhUVnLO.lT0MwqV9c2rpZs94wnPod4kst.hJhbC', 'NICHOLAS Daaiyefumasu', 273, 'sponsors/273.jpg', 1, 'PAR_USERS', 1, 43, '2015-03-26 12:22:49', '2015-04-22 10:02:43');

-- --------------------------------------------------------

--
-- Table structure for table `weekly_detail_setups`
--

DROP TABLE IF EXISTS `weekly_detail_setups`;
CREATE TABLE IF NOT EXISTS `weekly_detail_setups` (
`weekly_detail_setup_id` int(11) NOT NULL,
  `weekly_report_setup_id` int(11) NOT NULL,
  `weekly_report_no` int(11) NOT NULL,
  `weekly_weight_point` int(11) NOT NULL DEFAULT '0',
  `weekly_weight_percent` int(11) NOT NULL DEFAULT '0',
  `submission_date` date NOT NULL,
  `report_description` text
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=11 ;

--
-- Dumping data for table `weekly_detail_setups`
--

INSERT INTO `weekly_detail_setups` (`weekly_detail_setup_id`, `weekly_report_setup_id`, `weekly_report_no`, `weekly_weight_point`, `weekly_weight_percent`, `submission_date`, `report_description`) VALUES
(1, 1, 1, 10, 15, '2015-05-05', 'Opening'),
(2, 1, 2, 15, 15, '2015-05-06', 'Second Week'),
(3, 1, 3, 20, 20, '2015-05-15', 'Mid Term'),
(4, 1, 4, 30, 50, '2015-05-22', 'General C.A'),
(5, 2, 1, 5, 5, '2015-05-05', 'Opening Week'),
(6, 2, 2, 10, 10, '2015-05-06', 'Second Week'),
(7, 2, 3, 15, 20, '2015-05-07', 'Mid Term'),
(8, 2, 4, 20, 15, '2015-05-29', 'Assignment'),
(9, 2, 5, 25, 15, '2015-06-05', 'Class Work'),
(10, 2, 6, 30, 35, '2015-06-12', 'General C.A');

-- --------------------------------------------------------

--
-- Table structure for table `weekly_report_details`
--

DROP TABLE IF EXISTS `weekly_report_details`;
CREATE TABLE IF NOT EXISTS `weekly_report_details` (
`weekly_report_detail_id` int(11) NOT NULL,
  `weekly_report_id` int(11) DEFAULT NULL,
  `student_id` int(11) DEFAULT NULL,
  `weekly_ca` decimal(4,1) DEFAULT '0.0'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=69 ;

--
-- Dumping data for table `weekly_report_details`
--

INSERT INTO `weekly_report_details` (`weekly_report_detail_id`, `weekly_report_id`, `student_id`, `weekly_ca`) VALUES
(1, 1, 189, '8.0'),
(2, 1, 190, '5.0'),
(3, 1, 191, '9.0'),
(4, 1, 192, '6.0'),
(5, 1, 193, '4.0'),
(6, 1, 194, '7.0'),
(7, 1, 195, '7.0'),
(8, 1, 196, '5.0'),
(16, 2, 189, '5.6'),
(17, 2, 190, '2.0'),
(18, 2, 191, '3.0'),
(19, 2, 192, '9.0'),
(20, 2, 193, '8.0'),
(21, 2, 194, '7.0'),
(22, 2, 195, '7.0'),
(23, 2, 196, '6.0'),
(31, 3, 189, '6.0'),
(32, 3, 190, '9.0'),
(33, 3, 191, '8.0'),
(34, 3, 192, '7.0'),
(35, 3, 193, '6.0'),
(36, 3, 194, '9.0'),
(37, 3, 195, '5.0'),
(38, 3, 196, '8.0'),
(46, 4, 189, '5.0'),
(47, 4, 190, '6.0'),
(48, 4, 191, '3.0'),
(49, 4, 192, '8.0'),
(50, 4, 193, '9.0'),
(51, 4, 194, '7.0'),
(52, 4, 195, '6.0'),
(53, 4, 196, '8.0'),
(54, 5, 189, '11.0'),
(55, 5, 190, '9.0'),
(56, 5, 191, '12.0'),
(57, 5, 192, '9.0'),
(58, 5, 193, '8.0'),
(59, 5, 194, '10.0'),
(60, 5, 195, '8.0'),
(61, 5, 196, '7.0');

-- --------------------------------------------------------

--
-- Table structure for table `weekly_report_setups`
--

DROP TABLE IF EXISTS `weekly_report_setups`;
CREATE TABLE IF NOT EXISTS `weekly_report_setups` (
`weekly_report_setup_id` int(11) unsigned NOT NULL,
  `weekly_report` int(11) DEFAULT NULL,
  `classgroup_id` int(11) DEFAULT NULL,
  `academic_term_id` int(11) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=3 ;

--
-- Dumping data for table `weekly_report_setups`
--

INSERT INTO `weekly_report_setups` (`weekly_report_setup_id`, `weekly_report`, `classgroup_id`, `academic_term_id`) VALUES
(1, 4, 1, 1),
(2, 6, 2, 1);

-- --------------------------------------------------------

--
-- Table structure for table `weekly_reports`
--

DROP TABLE IF EXISTS `weekly_reports`;
CREATE TABLE IF NOT EXISTS `weekly_reports` (
`weekly_report_id` int(11) unsigned NOT NULL,
  `subject_classlevel_id` int(11) DEFAULT NULL,
  `weekly_detail_setup_id` int(11) DEFAULT NULL,
  `marked_status` int(11) NOT NULL DEFAULT '2',
  `notification_status` int(11) NOT NULL DEFAULT '2'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=6 ;

--
-- Dumping data for table `weekly_reports`
--

INSERT INTO `weekly_reports` (`weekly_report_id`, `subject_classlevel_id`, `weekly_detail_setup_id`, `marked_status`, `notification_status`) VALUES
(1, 22, 5, 1, 1),
(2, 24, 5, 1, 2),
(3, 23, 5, 1, 2),
(4, 21, 5, 1, 2),
(5, 22, 7, 1, 2);

-- --------------------------------------------------------

--
-- Stand-in structure for view `weekly_setupviews`
--
DROP VIEW IF EXISTS `weekly_setupviews`;
CREATE TABLE IF NOT EXISTS `weekly_setupviews` (
`weekly_report_setup_id` int(11) unsigned
,`weekly_report` int(11)
,`weekly_weight_point` int(11)
,`weekly_weight_percent` int(11)
,`classgroup_id` int(11)
,`academic_term_id` int(11)
,`weekly_detail_setup_id` int(11)
,`weekly_report_no` int(11)
,`report_description` text
,`submission_date` date
,`classgroup` varchar(50)
,`academic_term` varchar(50)
,`academic_year_id` int(11) unsigned
);
-- --------------------------------------------------------

--
-- Stand-in structure for view `weeklyreport_studentdetailsviews`
--
DROP VIEW IF EXISTS `weeklyreport_studentdetailsviews`;
CREATE TABLE IF NOT EXISTS `weeklyreport_studentdetailsviews` (
`weekly_report_id` int(11) unsigned
,`subject_classlevel_id` int(11)
,`weekly_detail_setup_id` int(11)
,`marked_status` int(11)
,`notification_status` int(11)
,`weekly_report_detail_id` int(11)
,`student_id` int(11)
,`student_no` varchar(50)
,`student_name` varchar(101)
,`gender` varchar(10)
,`weekly_ca` decimal(4,1)
,`weekly_report_no` int(11)
,`weekly_weight_percent` int(11)
,`report_description` text
,`submission_date` date
,`weekly_report_setup_id` int(11) unsigned
,`weekly_weight_point` int(11)
,`sponsor_id` int(11)
,`sponsor_no` varchar(10)
,`mobile_number1` varchar(20)
,`email` varchar(100)
,`sponsor_name` varchar(101)
,`subject_name` varchar(50)
,`class_id` int(11)
,`class_name` varchar(50)
,`classlevel_id` int(11)
,`classlevel` varchar(50)
,`classgroup_id` int(11) unsigned
,`academic_term_id` int(11)
,`academic_term` varchar(50)
);
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

-- --------------------------------------------------------

--
-- Structure for view `weekly_setupviews`
--
DROP TABLE IF EXISTS `weekly_setupviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `weekly_setupviews` AS select `a`.`weekly_report_setup_id` AS `weekly_report_setup_id`,`a`.`weekly_report` AS `weekly_report`,`b`.`weekly_weight_point` AS `weekly_weight_point`,`b`.`weekly_weight_percent` AS `weekly_weight_percent`,`a`.`classgroup_id` AS `classgroup_id`,`a`.`academic_term_id` AS `academic_term_id`,`b`.`weekly_detail_setup_id` AS `weekly_detail_setup_id`,`b`.`weekly_report_no` AS `weekly_report_no`,`b`.`report_description` AS `report_description`,`b`.`submission_date` AS `submission_date`,`c`.`classgroup` AS `classgroup`,`d`.`academic_term` AS `academic_term`,`d`.`academic_year_id` AS `academic_year_id` from (((`weekly_report_setups` `a` join `weekly_detail_setups` `b` on((`a`.`weekly_report_setup_id` = `b`.`weekly_report_setup_id`))) join `classgroups` `c` on((`a`.`classgroup_id` = `c`.`classgroup_id`))) join `academic_terms` `d` on((`a`.`academic_term_id` = `d`.`academic_term_id`)));

-- --------------------------------------------------------

--
-- Structure for view `weeklyreport_studentdetailsviews`
--
DROP TABLE IF EXISTS `weeklyreport_studentdetailsviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `weeklyreport_studentdetailsviews` AS select `f`.`weekly_report_id` AS `weekly_report_id`,`f`.`subject_classlevel_id` AS `subject_classlevel_id`,`f`.`weekly_detail_setup_id` AS `weekly_detail_setup_id`,`f`.`marked_status` AS `marked_status`,`f`.`notification_status` AS `notification_status`,`g`.`weekly_report_detail_id` AS `weekly_report_detail_id`,`g`.`student_id` AS `student_id`,`j`.`student_no` AS `student_no`,concat(`j`.`first_name`,' ',`j`.`surname`) AS `student_name`,`j`.`gender` AS `gender`,`g`.`weekly_ca` AS `weekly_ca`,`h`.`weekly_report_no` AS `weekly_report_no`,`h`.`weekly_weight_percent` AS `weekly_weight_percent`,`h`.`report_description` AS `report_description`,`h`.`submission_date` AS `submission_date`,`i`.`weekly_report_setup_id` AS `weekly_report_setup_id`,`h`.`weekly_weight_point` AS `weekly_weight_point`,`j`.`sponsor_id` AS `sponsor_id`,`k`.`sponsor_no` AS `sponsor_no`,`k`.`mobile_number1` AS `mobile_number1`,`k`.`email` AS `email`,concat(`k`.`first_name`,' ',`k`.`other_name`) AS `sponsor_name`,`b`.`subject_name` AS `subject_name`,`a`.`class_id` AS `class_id`,`c`.`class_name` AS `class_name`,`c`.`classlevel_id` AS `classlevel_id`,`d`.`classlevel` AS `classlevel`,`d`.`classgroup_id` AS `classgroup_id`,`a`.`academic_term_id` AS `academic_term_id`,`e`.`academic_term` AS `academic_term` from ((((((((((`subject_classlevels` `a` join `subjects` `b` on((`a`.`subject_id` = `b`.`subject_id`))) join `classrooms` `c` on((`a`.`class_id` = `c`.`class_id`))) join `classlevels` `d` on((`a`.`classlevel_id` = `d`.`classlevel_id`))) join `academic_terms` `e` on((`a`.`academic_term_id` = `e`.`academic_term_id`))) join `weekly_reports` `f` on((`a`.`subject_classlevel_id` = `f`.`subject_classlevel_id`))) join `weekly_report_details` `g` on((`f`.`weekly_report_id` = `g`.`weekly_report_id`))) join `weekly_detail_setups` `h` on((`f`.`weekly_detail_setup_id` = `h`.`weekly_detail_setup_id`))) join `weekly_report_setups` `i` on((`h`.`weekly_report_setup_id` = `i`.`weekly_report_setup_id`))) join `students` `j` on((`g`.`student_id` = `j`.`student_id`))) join `sponsors` `k` on((`j`.`sponsor_id` = `k`.`sponsor_id`)));

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
-- Indexes for table `weekly_detail_setups`
--
ALTER TABLE `weekly_detail_setups`
 ADD PRIMARY KEY (`weekly_detail_setup_id`);

--
-- Indexes for table `weekly_report_details`
--
ALTER TABLE `weekly_report_details`
 ADD PRIMARY KEY (`weekly_report_detail_id`), ADD KEY `exam_id` (`weekly_report_id`,`student_id`);

--
-- Indexes for table `weekly_report_setups`
--
ALTER TABLE `weekly_report_setups`
 ADD PRIMARY KEY (`weekly_report_setup_id`), ADD KEY `class_id` (`weekly_report`);

--
-- Indexes for table `weekly_reports`
--
ALTER TABLE `weekly_reports`
 ADD PRIMARY KEY (`weekly_report_id`);

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
MODIFY `exam_detail_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `exams`
--
ALTER TABLE `exams`
MODIFY `exam_id` int(11) unsigned NOT NULL AUTO_INCREMENT;
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
MODIFY `subject_classlevel_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=29;
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
MODIFY `teachers_subjects_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=13;
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
--
-- AUTO_INCREMENT for table `weekly_detail_setups`
--
ALTER TABLE `weekly_detail_setups`
MODIFY `weekly_detail_setup_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=11;
--
-- AUTO_INCREMENT for table `weekly_report_details`
--
ALTER TABLE `weekly_report_details`
MODIFY `weekly_report_detail_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=69;
--
-- AUTO_INCREMENT for table `weekly_report_setups`
--
ALTER TABLE `weekly_report_setups`
MODIFY `weekly_report_setup_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `weekly_reports`
--
ALTER TABLE `weekly_reports`
MODIFY `weekly_report_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=6;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
