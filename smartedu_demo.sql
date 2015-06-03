-- phpMyAdmin SQL Dump
-- version 4.2.7.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jun 02, 2015 at 03:02 PM
-- Server version: 5.6.20
-- PHP Version: 5.5.15

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `smartedu_demo`
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

DROP PROCEDURE IF EXISTS `proc_cloneSubjectsAssigned`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_cloneSubjectsAssigned`(IN `TermFromID` INT, IN `TermToID` INT)
BEGIN
	-- Check to see if records already exist in subject classlevel table for the TermToID academic term
	SET @Exist = (SELECT COUNT(*) FROM subject_classlevels WHERE academic_term_id=TermToID); 
    
    IF @Exist = 0 THEN
		Block1: BEGIN
			DECLARE done1 BOOLEAN DEFAULT FALSE;
			DECLARE SubClassLevlID, SubjectID, LevelID, ClassID INT;
			DECLARE cur1 CURSOR FOR 
			SELECT subject_classlevel_id, subject_id, classlevel_id, class_id FROM subject_classlevels
			WHERE academic_term_id=TermFromID ORDER BY subject_classlevel_id;
			DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;

			#Open The Cursor For Iterating Through The Recordset cur1
			OPEN cur1;
				REPEAT
				FETCH cur1 INTO SubClassLevlID, SubjectID, LevelID, ClassID;
					IF NOT done1 THEN	
						BEGIN
							-- Test to see if the record does not exist before inserting
							SET @chk = (SELECT COUNT(*) FROM subject_classlevels WHERE subject_id=SubjectID AND class_id=ClassID AND classlevel_id=LevelID AND academic_term_id=TermToID); 
							IF @chk = 0 THEN
								BEGIN
									-- Get the teacher for that subject from the TermFromID academic term
									SET @EmployeeID = (SELECT employee_id FROM teachers_subjects WHERE subject_classlevel_id=SubClassLevlID AND class_id=ClassID LIMIT 1);
                                    
									# Insert into subject classlevel those newly assigned subjects
									INSERT INTO subject_classlevels(subject_id, classlevel_id, class_id, academic_term_id)
									VALUES(SubjectID, LevelID, ClassID, TermToID);
                                    
									-- Get the newly inserted subject classlevel id
                                    SET @New_ID = LAST_INSERT_ID();
                                    
                                    -- insert into teachers subjects table with the new id
                                    INSERT INTO teachers_subjects(employee_id, class_id, subject_classlevel_id)
									VALUES(@EmployeeID, ClassID, @New_ID);
                                    
									-- Procedure Call -- To register the subjects to the students in that classroom 
									CALL proc_assignSubject2Students(@New_ID);
								END;
							END IF;
						END;
					END IF;
				UNTIL done1 END REPEAT;
			CLOSE cur1;	
		END Block1;	
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
		row_id int AUTO_INCREMENT, exam_detail_id INT, exam_id int, subject_classlevel_id int, subject_id int, classlevel_id int,
		class_id int, student_id int, subject_name varchar(80), class_name varchar(80), student_fullname varchar(180),
		ca int, exam int, ca_weight_point int, exam_weight_point int,
		academic_term_id int, academic_term varchar(80), exammarked_status_id int, academic_year_id int,
		academic_year varchar(80), classlevel varchar(80), classgroup_id int,
		studentSubjectTotal Decimal(6, 2), studentPercentTotal Decimal(6, 2), weightageTotal Decimal(6, 2), grade varchar(20),
		grade_abbr varchar(5), student_sum_total Decimal(6, 2), exam_perfect_score int, PRIMARY KEY (row_id)
	);
			
	-- TypeID values 1 for term while others for year
	IF TypeID = 1 THEN
		-- Insert Into the temporary table
		INSERT INTO ExamsDetailsResultTable(exam_detail_id, exam_id, subject_classlevel_id, subject_id, classlevel_id, 
			 class_id, student_id, subject_name, class_name, student_fullname, ca, exam, ca_weight_point, exam_weight_point,
			 academic_term_id, academic_term, exammarked_status_id, academic_year_id, academic_year, classlevel, classgroup_id)
		SELECT * FROM examsdetails_reportviews
		WHERE exammarked_status_id=1 AND academic_term_id=AcademicID;
	ELSE
		-- Insert Into the temporary table
		INSERT INTO ExamsDetailsResultTable(exam_detail_id, exam_id, subject_classlevel_id, subject_id, classlevel_id, 
			 class_id, student_id, subject_name, class_name, student_fullname, ca, exam, ca_weight_point, exam_weight_point,
			 academic_term_id, academic_term, exammarked_status_id, academic_year_id, academic_year, classlevel, classgroup_id)
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
						SELECT CAST((ca + exam) AS Decimal(6, 2)), CAST((((ca + exam) / (ca_weight_point + exam_weight_point)) * 100) 
						AS Decimal(6, 2)), CAST((ca_weight_point + exam_weight_point) AS Decimal(6, 2)) INTO @StudentSubjectTotal,  @StudentPercentTotal, @WeightageTotal
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
    
    -- Update the C.A with the calculated values from the weekly reports
    call proc_processWeeklyReportCA(TermID);
    
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

DROP PROCEDURE IF EXISTS `proc_processWeeklyReportCA`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_processWeeklyReportCA`(IN `TermID` INT)
Block0: BEGIN
	#Create a Temporary Table to Hold The Values for manupulations
	/*DROP TEMPORARY TABLE IF EXISTS SubjectCAResultTable;
	CREATE TEMPORARY TABLE IF NOT EXISTS SubjectCAResultTable 
	(
		-- Add the column definitions for the TABLE variable here
		row_id INT AUTO_INCREMENT,
		student_id INT,
        student_name VARCHAR(100),
        class_id INT,
		subject_id INT,
        subject_name VARCHAR(100),
		subject_classlevel_id INT,
		academic_term_id INT,
        calculated_ca DECIMAL(4,2),
		calculated_wp DECIMAL(4,1),
		PRIMARY KEY(row_id)
	);*/
    
	Block1: BEGIN
		-- Declare Variable to be used in looping through the recordset or cursor
		DECLARE done1 BOOLEAN DEFAULT FALSE;
		DECLARE StudentID, ClassID, CA_WP INT;
		DECLARE StudentName VARCHAR(100);
		
		DECLARE cur1 CURSOR FOR
		SELECT student_id, class_id, ca_weight_point, student_name FROM weeklyreport_studentdetailsviews 
		WHERE academic_term_id=TermID GROUP BY student_id, class_id, ca_weight_point;
		
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;
		#Open The Cursor For Iterating Through The Recordset cur1
		OPEN cur1;
			REPEAT
			FETCH cur1 INTO StudentID, ClassID, CA_WP, StudentName;
				IF NOT done1 THEN
					
					-- Second Iteration get the subjects a student offered during the weekly report for the academic term
					Block2: BEGIN
						-- Declare Variable to be used in looping through the recordset or cursor
						DECLARE done2 BOOLEAN DEFAULT FALSE;
						DECLARE SubjectID, SubClassLevel int;
                        DECLARE SubjectName VARCHAR(100);
						
						DECLARE cur2 CURSOR FOR
						SELECT subject_id, subject_classlevel_id, subject_name FROM weeklyreport_studentdetailsviews 
						WHERE student_id=StudentID AND class_id=ClassID AND academic_term_id=TermID AND marked_status=1
						GROUP BY subject_id, subject_classlevel_id, subject_name;
						
						DECLARE CONTINUE HANDLER FOR NOT FOUND SET done2 = TRUE;
						#Open The Cursor For Iterating Through The Recordset cur1
						OPEN cur2;
							REPEAT
							FETCH cur2 INTO SubjectID, SubClassLevel, SubjectName;
								IF NOT done2 THEN
								
									SET @TEMP_SUM = 0.0;
									-- Third Iteration computes each subjects score  student offered during the weekly report for the academic term
									Block3: BEGIN
										-- Declare Variable to be used in looping through the recordset or cursor
										DECLARE done3 BOOLEAN DEFAULT FALSE;
										DECLARE W_CA, WW_Point, WW_Percent FLOAT;
                                    	
										DECLARE cur3 CURSOR FOR
										SELECT  weekly_ca, weekly_weight_point, weekly_weight_percent FROM weeklyreport_studentdetailsviews 
										WHERE student_id=StudentID AND class_id=ClassID AND academic_term_id=TermID AND marked_status=1
										AND subject_id=SubjectID AND subject_classlevel_id=SubClassLevel;
										
										DECLARE CONTINUE HANDLER FOR NOT FOUND SET done3 = TRUE;
										#Open The Cursor For Iterating Through The Recordset cur1
										OPEN cur3;
											REPEAT
											FETCH cur3 INTO W_CA, WW_Point, WW_Percent;
												IF NOT done3 THEN
													BEGIN
														-- Get the sum of the weight point percent (100)
														SET @PercentSUM = (SELECT SUM(weekly_weight_percent) FROM weeklyreport_studentdetailsviews 
														WHERE student_id=StudentID AND class_id=ClassID AND academic_term_id=TermID AND marked_status=1
														AND subject_id=SubjectID AND subject_classlevel_id=SubClassLevel);
                                                        
                                                        -- Get the new weight point assigned to the weeks report ((25/100) * 30)
                                                        -- i.e the (weekly weight point percentage (/) divides the sum of the percentages) (*) multiply by the original C.A weight point
                                                        SET @Temp_WP = ((WW_Percent / @PercentSUM) * CA_WP);
                                                        -- Get the new calcualted C.A of the weeks report ((11/15) * (((25/100) * 30)))
                                                        -- i.e the (weekly C.A score (/) divides the weekly weight point) (*) multiply by the calculated weight point above
                                                        SET @Temp_CA = ((W_CA / WW_Point) * @Temp_WP);
                                                        -- Sum up all the calculated C.A weekly reports for the subjects
                                                        SET @TEMP_SUM = @TEMP_SUM + @TEMP_CA;
                                                        
													END;
                                                    
												END IF;
											UNTIL done3 END REPEAT;
										CLOSE cur3;		
									END Block3;
                                    
                                    Block3_1: BEGIN
										-- Get the exam details id for that subject
										SET @ExamDetailID = (SELECT exam_detail_id FROM examsdetails_reportviews 
										WHERE student_id=StudentID AND class_id=ClassID AND academic_term_id=TermID
										AND subject_id=SubjectID AND subject_classlevel_id=SubClassLevel);
										
                                        -- Udate the exam details table and set the students C.A for that subject with the calculated C.A score
										UPDATE exam_details SET ca=@TEMP_SUM WHERE exam_detail_id=@ExamDetailID;
										
										-- Save the calculated C.A for each subjects for each student
										/*INSERT INTO SubjectCAResultTable(
											student_id, student_name, class_id, subject_id, subject_name, 
											subject_classlevel_id, academic_term_id, calculated_ca, calculated_wp
										)
										VALUES(StudentID, StudentName, ClassID, SubjectID, SubjectName, SubClassLevel, TermID, @TEMP_SUM, CA_WP);*/
									END Block3_1;	
								END IF;
							UNTIL done2 END REPEAT;
						CLOSE cur2;		
					END Block2;	
					
				END IF;
			UNTIL done1 END REPEAT;
		CLOSE cur1;		
	END Block1;
END Block0$$

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=3 ;

--
-- Dumping data for table `academic_terms`
--

INSERT INTO `academic_terms` (`academic_term_id`, `academic_term`, `academic_year_id`, `term_status_id`, `term_type_id`, `exam_status_id`, `exam_setup_by`, `exam_setup_date`, `term_begins`, `term_ends`, `created_at`, `updated_at`) VALUES
(1, '2014/2015 Third Term', 1, 1, 3, 1, 1, '2015-05-15 03:05:22', '2015-04-02', '2015-07-31', '2015-05-15 03:02:22', '2015-06-02 10:22:54'),
(2, '2015/2016 First Term', 2, 2, 1, 2, 0, NULL, '2015-09-05', '2015-12-20', '2015-06-02 11:22:54', '2015-06-02 10:22:54');

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
(1, '2014/2015', 1, '2015-05-14 12:35:06', '2015-05-14 11:35:06'),
(2, '2015/2016', 2, '2015-06-02 11:19:32', '2015-06-02 10:19:32');

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=171 ;

--
-- Dumping data for table `acos`
--

INSERT INTO `acos` (`id`, `parent_id`, `model`, `foreign_key`, `alias`, `lft`, `rght`) VALUES
(1, NULL, NULL, NULL, 'controllers', 1, 340),
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
(31, 1, NULL, NULL, 'ClonesController', 60, 67),
(32, 31, NULL, NULL, 'index', 61, 62),
(33, 31, NULL, NULL, 'validateClone', 63, 64),
(34, 31, NULL, NULL, 'cloning', 65, 66),
(35, 1, NULL, NULL, 'DashboardController', 68, 85),
(36, 35, NULL, NULL, 'index', 69, 70),
(37, 35, NULL, NULL, 'tutor', 71, 72),
(38, 35, NULL, NULL, 'studentGender', 73, 74),
(39, 35, NULL, NULL, 'studentStauts', 75, 76),
(40, 35, NULL, NULL, 'studentPaymentStatus', 77, 78),
(41, 35, NULL, NULL, 'studentClasslevel', 79, 80),
(42, 35, NULL, NULL, 'classHeadTutor', 81, 82),
(43, 35, NULL, NULL, 'subjectHeadTutor', 83, 84),
(44, 1, NULL, NULL, 'EmployeesController', 86, 103),
(45, 44, NULL, NULL, 'autoComplete', 87, 88),
(46, 44, NULL, NULL, 'validate_form', 89, 90),
(47, 44, NULL, NULL, 'index', 91, 92),
(48, 44, NULL, NULL, 'register', 93, 94),
(49, 44, NULL, NULL, 'view', 95, 96),
(50, 44, NULL, NULL, 'adjust', 97, 98),
(51, 44, NULL, NULL, 'delete', 99, 100),
(52, 44, NULL, NULL, 'statusUpdate', 101, 102),
(53, 1, NULL, NULL, 'ExamsController', 104, 137),
(54, 53, NULL, NULL, 'index', 105, 106),
(55, 53, NULL, NULL, 'setup_validate', 107, 108),
(56, 53, NULL, NULL, 'setup_exam', 109, 110),
(57, 53, NULL, NULL, 'search_subjects_assigned', 111, 112),
(58, 53, NULL, NULL, 'search_subjects_examSetup', 113, 114),
(59, 53, NULL, NULL, 'enter_scores', 115, 116),
(60, 53, NULL, NULL, 'view_scores', 117, 118),
(61, 53, NULL, NULL, 'search_student_classlevel', 119, 120),
(62, 53, NULL, NULL, 'term_scorestd', 121, 122),
(63, 53, NULL, NULL, 'term_scorecls', 123, 124),
(64, 53, NULL, NULL, 'annual_scorestd', 125, 126),
(65, 53, NULL, NULL, 'annual_scorecls', 127, 128),
(66, 53, NULL, NULL, 'print_result', 129, 130),
(67, 53, NULL, NULL, 'chart', 131, 132),
(68, 53, NULL, NULL, 'chart_analysis', 133, 134),
(69, 53, NULL, NULL, 'chart_anal', 135, 136),
(70, 1, NULL, NULL, 'HomeController', 138, 155),
(71, 70, NULL, NULL, 'index', 139, 140),
(72, 70, NULL, NULL, 'setup', 141, 142),
(73, 70, NULL, NULL, 'students', 143, 144),
(74, 70, NULL, NULL, 'exam', 145, 146),
(75, 70, NULL, NULL, 'search_student', 147, 148),
(76, 70, NULL, NULL, 'term_scorestd', 149, 150),
(77, 70, NULL, NULL, 'annual_scorestd', 151, 152),
(78, 70, NULL, NULL, 'view_stdfees', 153, 154),
(79, 1, NULL, NULL, 'ItemsController', 156, 175),
(80, 79, NULL, NULL, 'index', 157, 158),
(81, 79, NULL, NULL, 'summary', 159, 160),
(82, 79, NULL, NULL, 'payment_status', 161, 162),
(83, 79, NULL, NULL, 'validateIfExist', 163, 164),
(84, 79, NULL, NULL, 'process_fees', 165, 166),
(85, 79, NULL, NULL, 'bill_students', 167, 168),
(86, 79, NULL, NULL, 'view_stdfees', 169, 170),
(87, 79, NULL, NULL, 'view_clsfees', 171, 172),
(88, 79, NULL, NULL, 'statusUpdate', 173, 174),
(89, 1, NULL, NULL, 'LocalGovtsController', 176, 179),
(90, 89, NULL, NULL, 'ajax_get_local_govt', 177, 178),
(91, 1, NULL, NULL, 'MessagesController', 180, 195),
(92, 91, NULL, NULL, 'index', 181, 182),
(93, 91, NULL, NULL, 'recipient', 183, 184),
(94, 91, NULL, NULL, 'delete_recipient', 185, 186),
(95, 91, NULL, NULL, 'send', 187, 188),
(96, 91, NULL, NULL, 'sendOne', 189, 190),
(97, 91, NULL, NULL, 'search_student_classlevel', 191, 192),
(98, 91, NULL, NULL, 'encrypt', 193, 194),
(99, 1, NULL, NULL, 'RecordsController', 196, 223),
(100, 99, NULL, NULL, 'deleteIDs', 197, 198),
(101, 99, NULL, NULL, 'academic_year', 199, 200),
(102, 99, NULL, NULL, 'index', 201, 202),
(103, 99, NULL, NULL, 'class_group', 203, 204),
(104, 99, NULL, NULL, 'class_level', 205, 206),
(105, 99, NULL, NULL, 'class_room', 207, 208),
(106, 99, NULL, NULL, 'weekly_report', 209, 210),
(107, 99, NULL, NULL, 'weekly_detail', 211, 212),
(108, 99, NULL, NULL, 'subject_group', 213, 214),
(109, 99, NULL, NULL, 'subject', 215, 216),
(110, 99, NULL, NULL, 'grade', 217, 218),
(111, 99, NULL, NULL, 'item', 219, 220),
(112, 99, NULL, NULL, 'item_bill', 221, 222),
(113, 1, NULL, NULL, 'SetupsController', 224, 227),
(114, 113, NULL, NULL, 'setup', 225, 226),
(115, 1, NULL, NULL, 'SponsorsController', 228, 243),
(116, 115, NULL, NULL, 'autoComplete', 229, 230),
(117, 115, NULL, NULL, 'validate_form', 231, 232),
(118, 115, NULL, NULL, 'index', 233, 234),
(119, 115, NULL, NULL, 'register', 235, 236),
(120, 115, NULL, NULL, 'view', 237, 238),
(121, 115, NULL, NULL, 'adjust', 239, 240),
(122, 115, NULL, NULL, 'delete', 241, 242),
(123, 1, NULL, NULL, 'StudentsClassesController', 244, 251),
(124, 123, NULL, NULL, 'assign', 245, 246),
(125, 123, NULL, NULL, 'search', 247, 248),
(126, 123, NULL, NULL, 'search_all', 249, 250),
(127, 1, NULL, NULL, 'StudentsController', 252, 267),
(128, 127, NULL, NULL, 'validate_form', 253, 254),
(129, 127, NULL, NULL, 'index', 255, 256),
(130, 127, NULL, NULL, 'view', 257, 258),
(131, 127, NULL, NULL, 'register', 259, 260),
(132, 127, NULL, NULL, 'adjust', 261, 262),
(133, 127, NULL, NULL, 'delete', 263, 264),
(134, 127, NULL, NULL, 'statusUpdate', 265, 266),
(135, 1, NULL, NULL, 'SubjectsController', 268, 305),
(136, 135, NULL, NULL, 'ajax_get_subjects', 269, 270),
(137, 135, NULL, NULL, 'add2class', 271, 272),
(138, 135, NULL, NULL, 'search_assign', 273, 274),
(139, 135, NULL, NULL, 'assign', 275, 276),
(140, 135, NULL, NULL, 'search_assignlevel', 277, 278),
(141, 135, NULL, NULL, 'assign_level', 279, 280),
(142, 135, NULL, NULL, 'search_all', 281, 282),
(143, 135, NULL, NULL, 'assign_tutor', 283, 284),
(144, 135, NULL, NULL, 'search_assigned', 285, 286),
(145, 135, NULL, NULL, 'delete_assign', 287, 288),
(146, 135, NULL, NULL, 'search_students', 289, 290),
(147, 135, NULL, NULL, 'updateStudentsSubjects', 291, 292),
(148, 135, NULL, NULL, 'index', 293, 294),
(149, 135, NULL, NULL, 'search_assigned2Staff', 295, 296),
(150, 135, NULL, NULL, 'search_students_subjects', 297, 298),
(151, 135, NULL, NULL, 'updateStudentsStaffSubjects', 299, 300),
(152, 135, NULL, NULL, 'search_subject', 301, 302),
(153, 135, NULL, NULL, 'view', 303, 304),
(154, 1, NULL, NULL, 'UsersController', 306, 323),
(155, 154, NULL, NULL, 'login', 307, 308),
(156, 154, NULL, NULL, 'logout', 309, 310),
(157, 154, NULL, NULL, 'index', 311, 312),
(158, 154, NULL, NULL, 'register', 313, 314),
(159, 154, NULL, NULL, 'forget_password', 315, 316),
(160, 154, NULL, NULL, 'adjust', 317, 318),
(161, 154, NULL, NULL, 'change', 319, 320),
(162, 154, NULL, NULL, 'statusUpdate', 321, 322),
(163, 1, NULL, NULL, 'WeeklyReportsController', 324, 339),
(164, 163, NULL, NULL, 'index', 325, 326),
(165, 163, NULL, NULL, 'report', 327, 328),
(166, 163, NULL, NULL, 'scores', 329, 330),
(167, 163, NULL, NULL, 'save_scores', 331, 332),
(168, 163, NULL, NULL, 'view', 333, 334),
(169, 163, NULL, NULL, 'send', 335, 336),
(170, 163, NULL, NULL, 'print_report', 337, 338);

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
(3, 2, 70, '1', '1', '1', '1'),
(4, 2, 130, '1', '1', '1', '1'),
(5, 2, 120, '1', '1', '1', '1'),
(6, 2, 121, '0', '0', '1', '0'),
(7, 2, 118, '-1', '-1', '-1', '-1'),
(8, 3, 1, '-1', '-1', '-1', '-1'),
(9, 3, 35, '1', '1', '1', '1'),
(10, 3, 53, '1', '1', '1', '1'),
(11, 3, 135, '1', '1', '1', '1'),
(12, 3, 137, '-1', '-1', '-1', '-1'),
(13, 3, 56, '-1', '-1', '-1', '-1'),
(14, 3, 13, '1', '1', '1', '1'),
(15, 3, 130, '1', '1', '1', '1'),
(16, 3, 27, '1', '1', '1', '1'),
(17, 3, 30, '1', '1', '1', '1'),
(18, 3, 50, '0', '0', '1', '0'),
(19, 4, 1, '-1', '-1', '-1', '-1'),
(20, 4, 35, '1', '1', '1', '1'),
(21, 4, 99, '1', '1', '1', '1'),
(22, 4, 13, '1', '1', '1', '1'),
(23, 4, 53, '1', '1', '1', '1'),
(24, 4, 56, '-1', '-1', '-1', '-1'),
(25, 4, 24, '1', '1', '1', '1'),
(26, 4, 127, '1', '1', '1', '1'),
(27, 4, 129, '1', '1', '1', '1'),
(28, 4, 130, '1', '1', '1', '1'),
(29, 4, 131, '1', '0', '0', '0'),
(30, 4, 132, '0', '0', '1', '0'),
(31, 4, 133, '0', '0', '0', '-1'),
(32, 4, 115, '1', '1', '1', '1'),
(33, 4, 118, '1', '1', '1', '1'),
(34, 4, 120, '1', '1', '1', '1'),
(35, 4, 119, '1', '0', '0', '0'),
(36, 4, 121, '0', '0', '1', '0'),
(37, 4, 122, '0', '0', '0', '-1'),
(38, 4, 44, '1', '1', '1', '1'),
(39, 4, 47, '1', '1', '1', '1'),
(40, 4, 48, '1', '0', '0', '0'),
(41, 4, 50, '0', '0', '1', '0'),
(42, 4, 51, '0', '0', '0', '-1'),
(43, 4, 135, '1', '1', '1', '1'),
(44, 4, 137, '1', '1', '1', '1'),
(45, 4, 79, '1', '1', '1', '1'),
(46, 4, 84, '-1', '-1', '-1', '-1'),
(47, 6, 1, '1', '1', '1', '1'),
(48, 6, 70, '-1', '-1', '-1', '-1');

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
-- Table structure for table `classgroups`
--

DROP TABLE IF EXISTS `classgroups`;
CREATE TABLE IF NOT EXISTS `classgroups` (
`classgroup_id` int(11) unsigned NOT NULL,
  `classgroup` varchar(50) DEFAULT NULL,
  `ca_weight_point` int(10) unsigned DEFAULT '0',
  `exam_weight_point` int(10) unsigned DEFAULT '0'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=3 ;

--
-- Dumping data for table `classgroups`
--

INSERT INTO `classgroups` (`classgroup_id`, `classgroup`, `ca_weight_point`, `exam_weight_point`) VALUES
(1, 'Junior Secondary School', 30, 70),
(2, 'Senior Secondary School', 30, 70);

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
-- Table structure for table `classrooms`
--

DROP TABLE IF EXISTS `classrooms`;
CREATE TABLE IF NOT EXISTS `classrooms` (
`class_id` int(11) NOT NULL,
  `class_name` varchar(50) DEFAULT NULL,
  `classlevel_id` int(11) DEFAULT NULL,
  `class_size` int(11) DEFAULT NULL,
  `class_status_id` int(3) DEFAULT '1'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

--
-- Dumping data for table `classrooms`
--

INSERT INTO `classrooms` (`class_id`, `class_name`, `classlevel_id`, `class_size`, `class_status_id`) VALUES
(1, 'JS 1 A', 1, NULL, 1),
(2, 'JS 2 A', 2, NULL, 1),
(3, 'JS 3 A', 3, NULL, 1),
(4, 'SS 1 A', 4, NULL, 1),
(5, 'SS 2 A', 5, NULL, 1),
(6, 'SS 3 A', 6, NULL, 1);

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=12 ;

--
-- Dumping data for table `employees`
--

INSERT INTO `employees` (`employee_id`, `employee_no`, `salutation_id`, `first_name`, `other_name`, `gender`, `birth_date`, `image_url`, `contact_address`, `employee_type_id`, `mobile_number1`, `mobile_number2`, `marital_status`, `country_id`, `state_id`, `local_govt_id`, `email`, `next_ofkin_name`, `next_ofkin_number`, `next_ofkin_relate`, `form_of_identity`, `identity_no`, `identity_expiry_date`, `status_id`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'STF0001', 1, 'DOE', 'JOHN', 'Male', NULL, NULL, NULL, NULL, '08180966334', '', '', NULL, NULL, NULL, 'ogbuchistanley@rocketmail.com', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, '2015-05-14 01:19:19', '2015-05-15 12:09:48'),
(2, 'STF0002', 1, 'ONE', 'TEACHER', NULL, NULL, NULL, NULL, NULL, '08180966334', NULL, NULL, NULL, NULL, NULL, 'ogbuchistanley@rocketmail.com', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-05-14 01:31:41', '2015-05-14 12:31:41'),
(3, 'STF0003', 1, 'TWO', 'TEACHER', NULL, NULL, NULL, NULL, NULL, '08180966334', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-05-14 01:32:08', '2015-05-14 12:32:08'),
(4, 'STF0004', 1, 'THREE', 'TEACHER', NULL, NULL, NULL, NULL, NULL, '08180966334', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-05-14 01:33:32', '2015-05-14 12:33:32'),
(5, 'STF0005', 1, 'FOUR', 'TEACHER', NULL, NULL, NULL, NULL, NULL, '08180966334', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-05-14 01:33:59', '2015-05-14 12:33:59'),
(6, 'STF0006', 1, 'FIVE', 'TEACHER', NULL, NULL, NULL, NULL, NULL, '08180966334', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-05-14 01:34:31', '2015-05-14 12:34:32'),
(7, 'STF0007', 1, 'Six', 'Teacher', NULL, NULL, NULL, NULL, NULL, '+2348030734377', NULL, NULL, NULL, NULL, NULL, 'kingsley4united@yahoo.com', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, '2015-05-14 08:23:00', '2015-05-14 19:23:00'),
(8, 'STF0008', 6, 'Seven', 'Teacher', NULL, NULL, NULL, NULL, NULL, '+2348030734377', NULL, NULL, NULL, NULL, NULL, 'kingsley4united@yahoo.com', NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, '2015-05-14 08:32:05', '2015-05-14 19:32:05'),
(9, 'STF0009', 5, 'Eight', 'Teacher', NULL, NULL, NULL, NULL, NULL, '+2348030734377', NULL, NULL, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-05-14 08:35:11', '2015-05-14 19:35:11'),
(11, 'STF0011', 7, 'Ten', 'TEACHER', 'Male', NULL, NULL, NULL, NULL, '+2348030734377', '', '', NULL, NULL, NULL, 'kingsley4united@yahoo.com', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, '2015-05-14 08:51:23', '2015-05-15 11:52:54');

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
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `employee_types`
--

DROP TABLE IF EXISTS `employee_types`;
CREATE TABLE IF NOT EXISTS `employee_types` (
`employee_type_id` int(11) unsigned NOT NULL,
  `employee_type` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=31 ;

--
-- Dumping data for table `exams`
--

INSERT INTO `exams` (`exam_id`, `class_id`, `subject_classlevel_id`, `exammarked_status_id`) VALUES
(1, 1, 195, 2),
(2, 1, 196, 2),
(3, 1, 197, 2),
(4, 1, 198, 2),
(5, 1, 199, 2),
(6, 2, 200, 2),
(7, 2, 201, 2),
(8, 2, 202, 2),
(9, 2, 203, 2),
(10, 2, 204, 2),
(11, 3, 205, 2),
(12, 3, 206, 2),
(13, 3, 207, 2),
(14, 3, 208, 2),
(15, 3, 209, 2),
(16, 4, 210, 2),
(17, 4, 211, 2),
(18, 4, 212, 2),
(19, 4, 213, 2),
(20, 4, 214, 2),
(21, 5, 215, 2),
(22, 5, 216, 2),
(23, 5, 217, 2),
(24, 5, 218, 2),
(25, 5, 219, 2),
(26, 6, 220, 2),
(27, 6, 221, 2),
(28, 6, 222, 2),
(29, 6, 223, 2),
(30, 6, 224, 2);

-- --------------------------------------------------------

--
-- Stand-in structure for view `examsdetails_reportviews`
--
DROP VIEW IF EXISTS `examsdetails_reportviews`;
CREATE TABLE IF NOT EXISTS `examsdetails_reportviews` (
`exam_detail_id` int(11)
,`exam_id` int(11) unsigned
,`subject_classlevel_id` int(11)
,`subject_id` int(11)
,`classlevel_id` int(11)
,`class_id` int(11)
,`student_id` int(10) unsigned
,`subject_name` varchar(50)
,`class_name` varchar(50)
,`student_fullname` varchar(152)
,`ca` decimal(4,2)
,`exam` decimal(4,2)
,`ca_weight_point` int(10) unsigned
,`exam_weight_point` int(10) unsigned
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
-- Table structure for table `exam_details`
--

DROP TABLE IF EXISTS `exam_details`;
CREATE TABLE IF NOT EXISTS `exam_details` (
`exam_detail_id` int(11) NOT NULL,
  `exam_id` int(11) DEFAULT NULL,
  `student_id` int(11) DEFAULT NULL,
  `ca` decimal(4,2) DEFAULT '0.00',
  `exam` decimal(4,2) DEFAULT '0.00'
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=209 ;

--
-- Dumping data for table `exam_details`
--

INSERT INTO `exam_details` (`exam_detail_id`, `exam_id`, `student_id`, `ca`, `exam`) VALUES
(1, 1, 1, '16.07', '0.00'),
(2, 1, 7, '15.60', '0.00'),
(3, 1, 13, '16.27', '0.00'),
(4, 1, 15, '24.00', '0.00'),
(5, 1, 25, '13.93', '0.00'),
(8, 2, 1, '17.80', '0.00'),
(9, 2, 7, '17.50', '0.00'),
(10, 2, 13, '17.50', '0.00'),
(11, 2, 15, '19.50', '0.00'),
(12, 2, 25, '20.70', '0.00'),
(15, 3, 1, '26.72', '0.00'),
(16, 3, 7, '21.39', '0.00'),
(17, 3, 13, '21.39', '0.00'),
(18, 3, 15, '23.83', '0.00'),
(19, 3, 25, '21.28', '0.00'),
(22, 4, 1, '22.35', '0.00'),
(23, 4, 7, '24.20', '0.00'),
(24, 4, 13, '22.25', '0.00'),
(25, 4, 15, '22.90', '0.00'),
(26, 4, 25, '19.85', '0.00'),
(29, 5, 1, '19.67', '0.00'),
(30, 5, 7, '20.89', '0.00'),
(31, 5, 13, '25.33', '0.00'),
(32, 5, 15, '25.22', '0.00'),
(33, 5, 25, '20.89', '0.00'),
(36, 6, 2, '25.25', '0.00'),
(37, 6, 8, '23.90', '0.00'),
(38, 6, 14, '21.55', '0.00'),
(39, 6, 16, '25.70', '0.00'),
(40, 6, 26, '24.90', '0.00'),
(43, 7, 2, '10.50', '0.00'),
(44, 7, 8, '7.50', '0.00'),
(45, 7, 14, '13.50', '0.00'),
(46, 7, 16, '13.50', '0.00'),
(47, 7, 26, '12.00', '0.00'),
(50, 8, 2, '21.40', '0.00'),
(51, 8, 8, '19.70', '0.00'),
(52, 8, 14, '21.90', '0.00'),
(53, 8, 16, '18.70', '0.00'),
(54, 8, 26, '19.20', '0.00'),
(57, 9, 2, '20.55', '0.00'),
(58, 9, 8, '23.30', '0.00'),
(59, 9, 14, '14.00', '0.00'),
(60, 9, 16, '18.45', '0.00'),
(61, 9, 26, '20.90', '0.00'),
(64, 10, 2, '21.50', '0.00'),
(65, 10, 8, '8.90', '0.00'),
(66, 10, 14, '15.70', '0.00'),
(67, 10, 16, '16.90', '0.00'),
(68, 10, 26, '18.50', '0.00'),
(71, 11, 3, '22.75', '0.00'),
(72, 11, 12, '19.60', '0.00'),
(73, 11, 17, '21.25', '0.00'),
(74, 11, 19, '19.95', '0.00'),
(75, 11, 27, '21.00', '0.00'),
(76, 11, 28, '24.05', '0.00'),
(78, 12, 3, '19.70', '0.00'),
(79, 12, 12, '22.00', '0.00'),
(80, 12, 17, '19.60', '0.00'),
(81, 12, 19, '21.20', '0.00'),
(82, 12, 27, '21.00', '0.00'),
(83, 12, 28, '17.70', '0.00'),
(85, 13, 3, '21.20', '0.00'),
(86, 13, 12, '17.90', '0.00'),
(87, 13, 17, '19.90', '0.00'),
(88, 13, 19, '16.10', '0.00'),
(89, 13, 27, '19.00', '0.00'),
(90, 13, 28, '19.15', '0.00'),
(92, 14, 3, '20.30', '0.00'),
(93, 14, 12, '19.50', '0.00'),
(94, 14, 17, '18.20', '0.00'),
(95, 14, 19, '18.60', '0.00'),
(96, 14, 27, '17.80', '0.00'),
(97, 14, 28, '7.50', '0.00'),
(99, 15, 3, '22.70', '0.00'),
(100, 15, 12, '23.20', '0.00'),
(101, 15, 17, '22.00', '0.00'),
(102, 15, 19, '20.75', '0.00'),
(103, 15, 27, '22.60', '0.00'),
(104, 15, 28, '24.80', '0.00'),
(106, 16, 9, '23.90', '0.00'),
(107, 16, 18, '24.30', '0.00'),
(108, 16, 22, '21.90', '0.00'),
(109, 16, 29, '19.80', '0.00'),
(113, 17, 9, '18.50', '0.00'),
(114, 17, 18, '18.80', '0.00'),
(115, 17, 22, '5.70', '0.00'),
(116, 17, 29, '19.10', '0.00'),
(120, 18, 9, '20.15', '0.00'),
(121, 18, 18, '20.75', '0.00'),
(122, 18, 22, '26.15', '0.00'),
(123, 18, 29, '21.25', '0.00'),
(127, 19, 9, '19.20', '0.00'),
(128, 19, 18, '20.50', '0.00'),
(129, 19, 22, '25.10', '0.00'),
(130, 19, 29, '22.70', '0.00'),
(134, 20, 9, '25.00', '0.00'),
(135, 20, 18, '20.70', '0.00'),
(136, 20, 22, '23.50', '0.00'),
(137, 20, 29, '22.30', '0.00'),
(141, 21, 5, '25.00', '0.00'),
(142, 21, 10, '21.75', '0.00'),
(143, 21, 20, '21.15', '0.00'),
(144, 21, 23, '26.25', '0.00'),
(145, 21, 30, '21.00', '0.00'),
(148, 22, 5, '14.90', '0.00'),
(149, 22, 10, '16.40', '0.00'),
(150, 22, 20, '20.30', '0.00'),
(151, 22, 23, '15.80', '0.00'),
(152, 22, 30, '17.30', '0.00'),
(155, 23, 5, '24.85', '0.00'),
(156, 23, 10, '22.70', '0.00'),
(157, 23, 20, '27.25', '0.00'),
(158, 23, 23, '21.80', '0.00'),
(159, 23, 30, '23.65', '0.00'),
(162, 24, 5, '15.80', '0.00'),
(163, 24, 10, '12.60', '0.00'),
(164, 24, 20, '17.70', '0.00'),
(165, 24, 23, '16.70', '0.00'),
(166, 24, 30, '16.20', '0.00'),
(169, 25, 5, '15.70', '0.00'),
(170, 25, 10, '14.50', '0.00'),
(171, 25, 20, '17.60', '0.00'),
(172, 25, 23, '14.70', '0.00'),
(173, 25, 30, '16.70', '0.00'),
(176, 26, 6, '25.35', '0.00'),
(177, 26, 11, '26.80', '0.00'),
(178, 26, 21, '25.80', '0.00'),
(179, 26, 24, '25.90', '0.00'),
(180, 26, 31, '26.00', '0.00'),
(183, 27, 6, '12.30', '0.00'),
(184, 27, 11, '21.00', '0.00'),
(185, 27, 21, '20.90', '0.00'),
(186, 27, 24, '16.80', '0.00'),
(187, 27, 31, '20.20', '0.00'),
(190, 28, 6, '18.60', '0.00'),
(191, 28, 11, '19.30', '0.00'),
(192, 28, 21, '20.80', '0.00'),
(193, 28, 24, '20.30', '0.00'),
(194, 28, 31, '20.00', '0.00'),
(197, 29, 6, '19.10', '0.00'),
(198, 29, 11, '17.20', '0.00'),
(199, 29, 21, '18.80', '0.00'),
(200, 29, 24, '16.30', '0.00'),
(201, 29, 31, '17.60', '0.00'),
(204, 30, 6, '15.60', '0.00'),
(205, 30, 11, '15.00', '0.00'),
(206, 30, 21, '16.30', '0.00'),
(207, 30, 24, '17.50', '0.00'),
(208, 30, 31, '19.00', '0.00');

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
,`ca_weight_point` int(10) unsigned
,`exam_weight_point` int(10) unsigned
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
  `school_name` varchar(200) NOT NULL,
  `school_address` text NOT NULL,
  `master_record_id` int(11) NOT NULL DEFAULT '0',
  `principal_id` int(11) NOT NULL,
  `vprincipal_id` int(11) NOT NULL,
  `school_logo` varchar(100) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=2 ;

--
-- Dumping data for table `master_setups`
--

INSERT INTO `master_setups` (`master_setup_id`, `setup`, `school_name`, `school_address`, `master_record_id`, `principal_id`, `vprincipal_id`, `school_logo`) VALUES
(1, 'smartedu', 'The Bells', '', 9, 2, 0, 'images/smartedu-icon.png');

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

--
-- Dumping data for table `remarks`
--

INSERT INTO `remarks` (`remark_id`, `class_teacher_remark`, `house_master_remark`, `principal_remark`, `student_id`, `academic_term_id`, `employee_id`) VALUES
(1, 'None', 'None', 'None', 3, 1, 4),
(2, 'None', 'None', 'None', 12, 1, 4),
(3, 'None', 'None', 'None', 17, 1, 4),
(4, 'None', 'None', 'None', 19, 1, 4),
(5, 'None', 'None', 'None', 27, 1, 4),
(6, 'None', 'None', 'None', 28, 1, 4);

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

--
-- Dumping data for table `sponsors`
--

INSERT INTO `sponsors` (`sponsor_id`, `sponsor_no`, `first_name`, `other_name`, `salutation_id`, `occupation`, `company_name`, `company_address`, `email`, `image_url`, `contact_address`, `local_govt_id`, `state_id`, `country_id`, `mobile_number1`, `mobile_number2`, `created_by`, `sponsorship_type_id`, `created_at`, `updated_at`) VALUES
(1, 'PAR0001', 'ONE', 'PARENT', 1, NULL, NULL, NULL, 'ogbuchistanley@rocketmail.com', NULL, NULL, NULL, NULL, NULL, '08180966334', '', 0, NULL, '2015-05-14 12:28:46', '2015-05-15 12:17:12'),
(2, 'PAR0002', 'TWO', 'PARENT', 1, NULL, NULL, NULL, 'ogbuchistanley@rocketmail.com', NULL, NULL, NULL, NULL, NULL, '08180966334', NULL, 1, NULL, '2015-05-14 01:36:04', '2015-05-14 12:36:04'),
(3, 'PAR0003', 'THREE', 'PARENT', 1, NULL, NULL, NULL, 'ogbuchistanley@rocketmail.com', NULL, NULL, NULL, NULL, NULL, '08180966334', NULL, 1, NULL, '2015-05-14 01:38:22', '2015-05-14 12:38:22'),
(4, 'PAR0004', 'FOUR ', 'PARENT', 1, NULL, NULL, NULL, 'stanley@smartedu.io', NULL, NULL, NULL, NULL, NULL, '08180966334', NULL, 1, NULL, '2015-05-14 01:39:09', '2015-05-14 12:39:09'),
(5, 'PAR0005', 'FIVE', 'PARENT', 1, NULL, NULL, NULL, 'molawa@smartedu.io', NULL, NULL, NULL, NULL, NULL, '08180966334', NULL, 1, NULL, '2015-05-14 01:40:39', '2015-05-14 12:40:39'),
(6, 'PAR0006', 'Six', 'Parent', 7, NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, '+2348030734377', NULL, 1, NULL, '2015-05-14 08:56:08', '2015-05-14 19:56:08');

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=32 ;

--
-- Dumping data for table `students`
--

INSERT INTO `students` (`student_id`, `sponsor_id`, `first_name`, `surname`, `other_name`, `student_no`, `image_url`, `gender`, `birth_date`, `class_id`, `religion`, `previous_school`, `academic_term_id`, `term_admitted`, `student_status_id`, `local_govt_id`, `state_id`, `country_id`, `relationtype_id`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 2, 'STUDENT ', 'TWO', '', 'STD0001', NULL, 'Male', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-14 09:44:37', '2015-05-14 20:44:37'),
(2, 2, 'ELISHA', 'MATTHEW', '', 'STD0002', NULL, 'Male', NULL, 2, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 12:58:02', '2015-05-15 11:58:02'),
(3, 2, 'DELE', 'THOMAS', '', 'STD0003', NULL, 'Male', NULL, 3, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 12:59:04', '2015-05-15 11:59:04'),
(4, 2, 'CYNTHIA', 'BASSEY', '', 'STD0004', NULL, 'Female', '1970-01-01', 1, NULL, NULL, 1, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 12:59:42', '2015-05-15 13:51:44'),
(5, 2, 'DEBORAH', 'ELLA', '', 'STD0005', NULL, 'Female', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 2, 1, '2015-05-15 01:01:15', '2015-05-15 12:01:15'),
(6, 2, 'JUMOKE', 'BELLO', '', 'STD0006', NULL, 'Female', NULL, 6, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:02:04', '2015-05-15 12:02:04'),
(7, 3, 'KING', 'ATTAHIRU', '', 'STD0007', NULL, 'Male', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 4, 1, '2015-05-15 01:03:48', '2015-05-15 12:03:48'),
(8, 3, 'CHELSEA', 'STEVEN', '', 'STD0008', NULL, 'Female', NULL, 2, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 6, 1, '2015-05-15 01:04:51', '2015-05-15 12:04:51'),
(9, 3, 'YUSUF', 'SHERRIFAT', '', 'STD0009', NULL, 'Female', NULL, 4, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 8, 1, '2015-05-15 01:06:04', '2015-05-15 12:06:04'),
(10, 3, 'DERICK', 'ROSE', '', 'STD0010', NULL, 'Female', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 9, 1, '2015-05-15 01:14:38', '2015-05-15 12:14:38'),
(11, 3, 'FRANK', 'MILLS', '', 'STD0011', NULL, 'Male', NULL, 6, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 7, 1, '2015-05-15 01:15:15', '2015-05-15 12:15:15'),
(12, 3, 'OBI', 'EZEKIEL', '', 'STD0012', NULL, 'Male', NULL, 3, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:16:26', '2015-05-15 12:16:27'),
(13, 4, 'OLA', 'DAVID', '', 'STD0013', NULL, 'Female', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:17:26', '2015-05-15 12:17:26'),
(14, 4, 'PETER', 'MOYA', '', 'STD0014', NULL, 'Male', NULL, 2, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:18:35', '2015-05-15 12:18:35'),
(15, 1, 'FEMI', 'THOMAS', '', 'STD0015', NULL, 'Male', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 6, 1, '2015-05-15 01:21:35', '2015-05-15 12:21:35'),
(16, 1, 'LEKAN', 'SALAMI', '', 'STD0016', NULL, 'Male', NULL, 2, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:22:58', '2015-05-15 12:22:58'),
(17, 1, 'ELVIS', 'OZUMBA', '', 'STD0017', NULL, 'Male', NULL, 3, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 8, 1, '2015-05-15 01:23:48', '2015-05-15 12:23:48'),
(18, 1, 'RACHEL', 'NIKE', '', 'STD0018', NULL, 'Female', NULL, 4, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 5, 1, '2015-05-15 01:25:55', '2015-05-15 12:25:55'),
(19, 4, 'ONY', 'KEM', '', 'STD0019', NULL, 'Male', NULL, 3, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:25:58', '2015-05-15 12:25:59'),
(20, 1, 'AYODELE', 'SMITH', '', 'STD0020', NULL, 'Male', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 9, 1, '2015-05-15 01:26:37', '2015-05-15 12:26:37'),
(21, 1, 'BELLA', 'BOLTON', '', 'STD0021', NULL, 'Male', NULL, 6, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 9, 1, '2015-05-15 01:28:04', '2015-05-15 12:28:04'),
(22, 4, 'KACHI', 'OWO', '', 'STD0022', NULL, 'Female', NULL, 4, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:28:10', '2015-05-15 12:28:10'),
(23, 4, 'MARIAM', 'ADEWUSI', '', 'STD0023', NULL, 'Male', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:28:49', '2015-05-15 12:28:49'),
(24, 4, 'EMMANUEL', 'BASS', '', 'STD0024', NULL, 'Male', NULL, 6, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:29:32', '2015-05-15 12:29:32'),
(25, 5, 'PAMILERIN', 'MOSES', '', 'STD0025', NULL, 'Male', NULL, 1, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:30:40', '2015-05-15 12:30:40'),
(26, 5, 'EJINNE', 'COLLINS', '', 'STD0026', NULL, 'Female', NULL, 2, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:31:15', '2015-05-15 12:31:15'),
(27, 5, 'MARY', 'ONYELI', '', 'STD0027', NULL, 'Male', NULL, 3, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:32:16', '2015-05-15 12:32:16'),
(28, 5, 'DAVID', 'BECHKAM', '', 'STD0028', NULL, 'Male', NULL, 3, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:32:42', '2015-05-15 12:32:42'),
(29, 5, 'ONYEKACHI', 'PETERS', '', 'STD0029', NULL, 'Female', NULL, 4, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:33:27', '2015-05-15 12:33:27'),
(30, 5, 'CATHERINE', 'ADE', '', 'STD0030', NULL, 'Female', NULL, 5, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:34:33', '2015-05-15 12:34:33'),
(31, 5, 'BOLU', 'DAVIES', '', 'STD0031', NULL, 'Female', NULL, 6, NULL, NULL, NULL, NULL, 1, NULL, 0, 140, 1, 1, '2015-05-15 01:35:28', '2015-05-15 12:35:28');

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=32 ;

--
-- Dumping data for table `students_classes`
--

INSERT INTO `students_classes` (`student_class_id`, `student_id`, `class_id`, `academic_year_id`) VALUES
(1, 1, 1, 1),
(2, 2, 2, 1),
(3, 3, 3, 1),
(31, 4, 1, 1),
(4, 5, 5, 1),
(5, 6, 6, 1),
(6, 7, 1, 1),
(7, 8, 2, 1),
(8, 9, 4, 1),
(9, 10, 5, 1),
(10, 11, 6, 1),
(11, 12, 3, 1),
(12, 13, 1, 1),
(13, 14, 2, 1),
(14, 15, 1, 1),
(15, 16, 2, 1),
(16, 17, 3, 1),
(17, 18, 4, 1),
(18, 19, 3, 1),
(19, 20, 5, 1),
(20, 21, 6, 1),
(21, 22, 4, 1),
(22, 23, 5, 1),
(23, 24, 6, 1),
(24, 25, 1, 1),
(25, 26, 2, 1),
(26, 27, 3, 1),
(27, 28, 3, 1),
(28, 29, 4, 1),
(29, 30, 5, 1),
(30, 31, 6, 1);

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
,`academic_term_id` int(11)
,`academic_term` varchar(50)
);
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
-- Table structure for table `subjects`
--

DROP TABLE IF EXISTS `subjects`;
CREATE TABLE IF NOT EXISTS `subjects` (
`subject_id` int(3) NOT NULL,
  `subject_name` varchar(50) DEFAULT NULL,
  `subject_abbr` varchar(20) DEFAULT NULL,
  `subject_group_id` int(11) DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=47 ;

--
-- Dumping data for table `subjects`
--

INSERT INTO `subjects` (`subject_id`, `subject_name`, `subject_abbr`, `subject_group_id`) VALUES
(1, 'English Language', 'ENG', 2),
(2, 'Mathematics', 'MAT', 1),
(3, 'Basic Science', 'B. SCI', 3),
(4, 'Basic Technology', 'B. TECH', 7),
(5, 'Business Studies', 'BUS. STDS', 6),
(6, 'Social Studies', 'SOC STD', 5),
(7, 'French Language', 'FRE', 2),
(8, 'Physical & Health Education', 'PHE', 3),
(9, 'Computer  Science', 'COMP.SCI', 1),
(10, 'Visual Arts', 'V.ARTS', 7),
(11, 'Hausa Language', 'HAU', 2),
(12, 'Igbo Language', 'IGB', 2),
(13, 'Yoruba Language', 'YOR', 2),
(14, 'Agricultural Science', 'AGR SCI', 3),
(15, 'Home Economics', 'H.ECONS', 7),
(16, 'Christain Religious Studies', 'C.R.S.', 5),
(17, 'Islamic Religious Studies', 'I.R.S', 5),
(18, 'Geography', 'GEO', 5),
(19, 'Literature-In-English', 'LIT', 2),
(20, 'History ', 'HIS', 5),
(21, 'Physics', 'PHY', 3),
(22, 'Chemistry', 'CHEM', 3),
(23, 'Biology', 'BIO', 3),
(24, 'Foods & Nutrition', 'F&N', 7),
(25, 'Technical Drawing', 'T.D', 7),
(26, 'Music', 'MUS', 7),
(27, 'Metal Work', 'M.WRK', 7),
(28, 'Electronics', 'ELECT', 7),
(29, 'Wood Work', 'WD WRK', 7),
(30, 'Commerce', 'COM', 6),
(31, 'Accounting', 'ACC', 6),
(32, 'Economics', 'ECONS', 6),
(33, 'Government', 'GOV', 5),
(34, 'Further Mathematics', 'F.MATHS', 1),
(35, 'Animal Husbandry', 'ANI. HUS', 3),
(36, 'Data Processing', 'DAT', 1),
(37, 'Information & Communication Technology', 'ICT', 1),
(38, 'Civic Education', 'CIV', 5),
(39, 'Fine Arts', 'F.ARTS', 7),
(40, 'Creative Craft', 'Cat. Craft', 7),
(41, 'Paint & Decoration', 'P&D', 7),
(42, 'Chinese', 'CHIN', 2),
(43, 'Building Construction', 'BLD CONSTR', 7),
(44, 'Arabic ', 'ARA', 2),
(45, 'Auto Mechanic', 'AUTO', 7),
(46, 'Health Science', 'H. SCI', 7);

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=61 ;

--
-- Dumping data for table `subject_classlevels`
--

INSERT INTO `subject_classlevels` (`subject_classlevel_id`, `subject_id`, `classlevel_id`, `class_id`, `academic_term_id`, `examstatus_id`) VALUES
(2, 1, 1, 1, 1, 1),
(32, 1, 1, 1, 2, 2),
(10, 1, 2, 2, 1, 1),
(40, 1, 2, 2, 2, 2),
(14, 1, 3, 3, 1, 1),
(44, 1, 3, 3, 2, 2),
(16, 1, 4, 4, 1, 1),
(46, 1, 4, 4, 2, 2),
(23, 1, 5, 5, 1, 1),
(53, 1, 5, 5, 2, 2),
(28, 1, 6, 6, 1, 1),
(58, 1, 6, 6, 2, 2),
(1, 2, 1, 1, 1, 1),
(31, 2, 1, 1, 2, 2),
(9, 2, 2, 2, 1, 1),
(39, 2, 2, 2, 2, 2),
(13, 2, 3, 3, 1, 1),
(43, 2, 3, 3, 2, 2),
(17, 2, 4, 4, 1, 1),
(47, 2, 4, 4, 2, 2),
(24, 2, 5, 5, 1, 1),
(54, 2, 5, 5, 2, 2),
(30, 2, 6, 6, 1, 1),
(60, 2, 6, 6, 2, 2),
(4, 3, 1, 1, 1, 1),
(34, 3, 1, 1, 2, 2),
(6, 3, 2, 2, 1, 1),
(36, 3, 2, 2, 2, 2),
(11, 3, 3, 3, 1, 1),
(41, 3, 3, 3, 2, 2),
(5, 4, 1, 1, 1, 1),
(35, 4, 1, 1, 2, 2),
(7, 4, 2, 2, 1, 1),
(37, 4, 2, 2, 2, 2),
(12, 4, 3, 3, 1, 1),
(42, 4, 3, 3, 2, 2),
(19, 21, 4, 4, 1, 1),
(49, 21, 4, 4, 2, 2),
(25, 21, 5, 5, 1, 1),
(55, 21, 5, 5, 2, 2),
(29, 21, 6, 6, 1, 1),
(59, 21, 6, 6, 2, 2),
(20, 22, 4, 4, 1, 1),
(50, 22, 4, 4, 2, 2),
(22, 22, 5, 5, 1, 1),
(52, 22, 5, 5, 2, 2),
(27, 22, 6, 6, 1, 1),
(57, 22, 6, 6, 2, 2),
(18, 23, 4, 4, 1, 1),
(48, 23, 4, 4, 2, 2),
(21, 23, 5, 5, 1, 1),
(51, 23, 5, 5, 2, 2),
(26, 23, 6, 6, 1, 1),
(56, 23, 6, 6, 2, 2),
(3, 38, 1, 1, 1, 1),
(33, 38, 1, 1, 2, 2),
(8, 38, 2, 2, 1, 1),
(38, 38, 2, 2, 2, 2),
(15, 38, 3, 3, 1, 1),
(45, 38, 3, 3, 2, 2);

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
(1, 1, 1),
(1, 1, 2),
(1, 1, 3),
(1, 1, 4),
(1, 1, 5),
(2, 2, 6),
(2, 2, 7),
(2, 2, 8),
(2, 2, 9),
(2, 2, 10),
(3, 3, 11),
(3, 3, 12),
(3, 3, 13),
(3, 3, 14),
(3, 3, 15),
(4, 1, 1),
(5, 5, 21),
(5, 5, 22),
(5, 5, 23),
(5, 5, 24),
(5, 5, 25),
(6, 6, 26),
(6, 6, 27),
(6, 6, 28),
(6, 6, 29),
(6, 6, 30),
(7, 1, 1),
(7, 1, 2),
(7, 1, 3),
(7, 1, 4),
(7, 1, 5),
(8, 2, 6),
(8, 2, 7),
(8, 2, 8),
(8, 2, 9),
(8, 2, 10),
(9, 4, 16),
(9, 4, 17),
(9, 4, 18),
(9, 4, 19),
(9, 4, 20),
(10, 5, 21),
(10, 5, 22),
(10, 5, 23),
(10, 5, 24),
(10, 5, 25),
(11, 6, 26),
(11, 6, 27),
(11, 6, 28),
(11, 6, 29),
(11, 6, 30),
(12, 3, 11),
(12, 3, 12),
(12, 3, 13),
(12, 3, 14),
(12, 3, 15),
(13, 1, 1),
(13, 1, 2),
(13, 1, 3),
(13, 1, 4),
(13, 1, 5),
(14, 2, 6),
(14, 2, 7),
(14, 2, 8),
(14, 2, 9),
(14, 2, 10),
(15, 1, 1),
(15, 1, 2),
(15, 1, 3),
(15, 1, 4),
(15, 1, 5),
(16, 2, 6),
(16, 2, 7),
(16, 2, 8),
(16, 2, 9),
(16, 2, 10),
(17, 3, 11),
(17, 3, 12),
(17, 3, 13),
(17, 3, 14),
(17, 3, 15),
(18, 4, 16),
(18, 4, 17),
(18, 4, 18),
(18, 4, 19),
(18, 4, 20),
(19, 3, 11),
(19, 3, 12),
(19, 3, 13),
(19, 3, 14),
(19, 3, 15),
(20, 5, 21),
(20, 5, 22),
(20, 5, 23),
(20, 5, 24),
(20, 5, 25),
(21, 6, 26),
(21, 6, 27),
(21, 6, 28),
(21, 6, 29),
(21, 6, 30),
(22, 4, 16),
(22, 4, 17),
(22, 4, 18),
(22, 4, 19),
(22, 4, 20),
(23, 5, 21),
(23, 5, 22),
(23, 5, 23),
(23, 5, 24),
(23, 5, 25),
(24, 6, 26),
(24, 6, 27),
(24, 6, 28),
(24, 6, 29),
(24, 6, 30),
(25, 1, 1),
(25, 1, 2),
(25, 1, 3),
(25, 1, 4),
(25, 1, 5),
(26, 2, 6),
(26, 2, 7),
(26, 2, 8),
(26, 2, 9),
(26, 2, 10),
(27, 3, 11),
(27, 3, 12),
(27, 3, 13),
(27, 3, 14),
(27, 3, 15),
(28, 3, 11),
(28, 3, 12),
(28, 3, 13),
(28, 3, 14),
(28, 3, 15),
(29, 4, 16),
(29, 4, 17),
(29, 4, 18),
(29, 4, 19),
(29, 4, 20),
(30, 5, 21),
(30, 5, 22),
(30, 5, 23),
(30, 5, 24),
(30, 5, 25),
(31, 6, 26),
(31, 6, 27),
(31, 6, 28),
(31, 6, 29),
(31, 6, 30);

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

--
-- Dumping data for table `teachers_classes`
--

INSERT INTO `teachers_classes` (`teacher_class_id`, `employee_id`, `class_id`, `academic_year_id`, `created_at`, `updated_at`) VALUES
(1, 2, 1, 1, '2015-05-15 02:53:44', '2015-05-15 13:53:44'),
(2, 3, 2, 1, '2015-05-15 02:53:59', '2015-05-15 13:53:59'),
(3, 4, 3, 1, '2015-05-15 02:54:10', '2015-05-15 13:54:10'),
(4, 5, 4, 1, '2015-05-15 02:54:23', '2015-05-15 13:54:23'),
(5, 6, 5, 1, '2015-05-15 02:54:37', '2015-05-15 13:54:37'),
(6, 7, 6, 1, '2015-05-15 02:54:53', '2015-05-15 13:54:53');

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=61 ;

--
-- Dumping data for table `teachers_subjects`
--

INSERT INTO `teachers_subjects` (`teachers_subjects_id`, `employee_id`, `class_id`, `subject_classlevel_id`, `assign_date`) VALUES
(1, 6, 6, 29, '2015-05-15 01:50:31'),
(2, 5, 6, 30, '2015-05-15 01:50:24'),
(3, 2, 1, 4, '2015-05-15 01:48:20'),
(4, 3, 1, 5, '2015-05-15 01:48:27'),
(5, 4, 1, 3, '2015-05-15 01:48:30'),
(6, 5, 1, 2, '2015-05-15 01:48:38'),
(7, 6, 1, 1, '2015-05-15 01:48:42'),
(8, 2, 4, 18, '2015-05-15 01:48:51'),
(9, 2, 2, 6, '2015-05-15 01:48:56'),
(10, 3, 4, 20, '2015-05-15 01:48:57'),
(11, 3, 2, 7, '2015-05-15 01:49:00'),
(12, 4, 4, 16, '2015-05-15 01:49:02'),
(13, 4, 2, 8, '2015-05-15 01:49:03'),
(14, 5, 2, 10, '2015-05-15 01:49:05'),
(15, 5, 4, 17, '2015-05-15 01:49:06'),
(16, 6, 2, 9, '2015-05-15 01:49:09'),
(17, 6, 4, 19, '2015-05-15 01:49:15'),
(18, 2, 3, 11, '2015-05-15 01:49:21'),
(19, 3, 3, 12, '2015-05-15 01:49:26'),
(20, 2, 5, 21, '2015-05-15 01:49:28'),
(21, 4, 3, 15, '2015-05-15 01:49:32'),
(22, 3, 5, 22, '2015-05-15 01:49:34'),
(23, 5, 3, 14, '2015-05-15 01:49:35'),
(24, 4, 5, 23, '2015-05-15 01:49:38'),
(25, 6, 3, 13, '2015-05-15 01:49:38'),
(26, 5, 5, 24, '2015-05-15 01:49:43'),
(27, 6, 5, 25, '2015-05-15 01:49:49'),
(28, 2, 6, 26, '2015-05-15 01:50:03'),
(29, 3, 6, 27, '2015-05-15 01:50:09'),
(30, 4, 6, 28, '2015-05-15 01:50:14'),
(31, 6, 1, 31, '2015-06-02 12:54:54'),
(32, 5, 1, 32, '2015-06-02 12:54:54'),
(33, 4, 1, 33, '2015-06-02 12:54:54'),
(34, 2, 1, 34, '2015-06-02 12:54:54'),
(35, 3, 1, 35, '2015-06-02 12:54:54'),
(36, 2, 2, 36, '2015-06-02 12:54:54'),
(37, 3, 2, 37, '2015-06-02 12:54:54'),
(38, 4, 2, 38, '2015-06-02 12:54:54'),
(39, 6, 2, 39, '2015-06-02 12:54:54'),
(40, 5, 2, 40, '2015-06-02 12:54:54'),
(41, 2, 3, 41, '2015-06-02 12:54:54'),
(42, 3, 3, 42, '2015-06-02 12:54:54'),
(43, 6, 3, 43, '2015-06-02 12:54:54'),
(44, 5, 3, 44, '2015-06-02 12:54:54'),
(45, 4, 3, 45, '2015-06-02 12:54:54'),
(46, 4, 4, 46, '2015-06-02 12:54:54'),
(47, 5, 4, 47, '2015-06-02 12:54:54'),
(48, 2, 4, 48, '2015-06-02 12:54:54'),
(49, 6, 4, 49, '2015-06-02 12:54:54'),
(50, 3, 4, 50, '2015-06-02 12:54:54'),
(51, 2, 5, 51, '2015-06-02 12:54:54'),
(52, 3, 5, 52, '2015-06-02 12:54:54'),
(53, 4, 5, 53, '2015-06-02 12:54:54'),
(54, 5, 5, 54, '2015-06-02 12:54:54'),
(55, 6, 5, 55, '2015-06-02 12:54:54'),
(56, 2, 6, 56, '2015-06-02 12:54:54'),
(57, 3, 6, 57, '2015-06-02 12:54:54'),
(58, 4, 6, 58, '2015-06-02 12:54:54'),
(59, 6, 6, 59, '2015-06-02 12:54:54'),
(60, 5, 6, 60, '2015-06-02 12:54:54');

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=19 ;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `password`, `display_name`, `type_id`, `image_url`, `user_role_id`, `group_alias`, `status_id`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'smartedu', '$2a$10$NfmOYa5oiakpJMzoS5y9Z.83aGg7o0ZaVkL2XD4JuKgJLM8p4FfQu', 'SmartEdu App', 0, NULL, 7, 'ADM_USERS', 1, 1, '2015-03-22 04:36:45', '2015-03-26 08:00:29'),
(2, 'PAR0001', '$2a$10$u.N0z/A7UfLy3aAqHtZoxODR1RZUnfarhIfFe5TUzltCaFErGemnm', 'ONE PARENT', 1, 'sponsors/1.jpg', 1, 'PAR_USERS', 1, 1, '2015-05-14 12:28:46', '2015-05-20 11:23:35'),
(3, 'STF0001', '$2a$10$zDMTCYVcfXVuca5foh2AsOIFgK.2HD3QYHe7CUTbGeV1u3nXKq9ES', 'DOE JOHN', 1, 'employees/1.jpg', 7, 'ADM_USERS', 1, 1, '2015-05-14 01:21:17', '2015-05-15 12:20:44'),
(4, 'STF0002', '$2a$10$rtG/HxkCAE0K/.jnZzKkVOK/9Q8nM.sdcZLY6PhYYHNENlkyHPL8u', 'ONE TEACHER', 2, 'employees/2.jpg', 4, 'ICT_USERS', 1, 1, '2015-05-14 01:31:41', '2015-06-02 12:57:47'),
(5, 'STF0003', '$2a$10$MPyYxK13cb.RX6JPYx95rOsEl7Kcw2tg20sW1SuOcdgdLGSe5r.CC', 'TWO TEACHER', 3, 'employees/3.jpg', 3, 'STF_USERS', 1, 1, '2015-05-14 01:32:08', '2015-05-14 12:32:08'),
(6, 'STF0004', '$2a$10$RwysqVrTWgD6NfqnEh8kPOj8EUJWTcvabazpFc/noMwZ1tXqdh6zm', 'THREE TEACHER', 4, 'employees/4.jpg', 3, 'STF_USERS', 1, 1, '2015-05-14 01:33:32', '2015-05-14 12:33:32'),
(7, 'STF0005', '$2a$10$yw9JbbEJLfhpTW8dp0Izy.tX2H6fl3Uo7vHZC61rIWwgH5/H4R8WG', 'FOUR TEACHER', 5, 'employees/5.jpg', 3, 'STF_USERS', 1, 1, '2015-05-14 01:33:59', '2015-05-14 12:33:59'),
(8, 'STF0006', '$2a$10$dwJXoXh8bknPji/udDFNv.sI9BK0yTUrk5zTb0ZJMgqz5YQVAqCVW', 'FIVE TEACHER', 6, 'employees/6.jpg', 3, 'STF_USERS', 1, 1, '2015-05-14 01:34:31', '2015-05-14 12:34:32'),
(9, 'PAR0002', '$2a$10$oeYXgBtSnTbi1j7dOlet8.FCaQ.aRgPOSjiSVdxKhviprCPI1CLte', 'TWO PARENT', 2, 'sponsors/2.jpg', 1, 'PAR_USERS', 1, 1, '2015-05-14 01:36:04', '2015-05-14 12:36:04'),
(10, 'PAR0003', '$2a$10$RafaBrDCoh6RoF485n5bb.PQ.77AxAKaKA6CjDzeawush34JnE/6S', 'THREE PARENT', 3, 'sponsors/3.jpg', 1, 'PAR_USERS', 1, 1, '2015-05-14 01:38:22', '2015-05-14 12:38:22'),
(11, 'PAR0004', '$2a$10$TMLXkaSstVGMdVwinoM0Qe..wE/9VTCeHrMduocbTyF2bBpxN04P2', 'FOUR  PARENT', 4, 'sponsors/4.jpg', 1, 'PAR_USERS', 1, 1, '2015-05-14 01:39:09', '2015-05-14 12:39:09'),
(12, 'PAR0005', '$2a$10$V0PCG4NxPfKMZyq7xDh5j.XPU1fmk9JlE3H28Z4PzOkkVUjJrz3aC', 'FIVE PARENT', 5, 'sponsors/5.jpg', 1, 'PAR_USERS', 1, 1, '2015-05-14 01:40:39', '2015-05-14 12:40:39'),
(13, 'STF0007', '$2a$10$bTHxaM2sQ2Ohcgl0SS/w3On0yGt/HBMEGYVY8f5L7Kz31jy2CMFb6', 'Six Teacher', 7, 'employees/7.jpg', 3, 'STF_USERS', 1, 1, '2015-05-14 08:23:00', '2015-05-20 11:25:56'),
(14, 'STF0008', '$2a$10$Smbc7W6F0sxJT5OHV6lhL.fidOaeJ0g3nE0qzXQuTkYFeFb5EaJ.q', 'Seven Teacher', 8, 'employees/8.jpg', 3, 'STF_USERS', 1, 1, '2015-05-14 08:32:05', '2015-05-20 11:25:56'),
(15, 'STF0009', '$2a$10$7ys5sCtDb0rweT/jhGXcnuJFBySCABwdAldMvcJOlv5S2VNr/l5la', 'Eight Teacher', 9, 'employees/9.jpg', 3, 'STF_USERS', 1, 1, '2015-05-14 08:35:11', '2015-05-20 11:25:56'),
(17, 'STF0011', '$2a$10$hEtI69SRaf/uZFHZ9fSP8OCuFf19UqrxMH8fY3kTu7ZVo/spUbt/2', 'Ten TEACHER', 11, 'employees/11.jpg', 3, 'STF_USERS', 1, 1, '2015-05-14 08:51:23', '2015-05-20 11:25:56'),
(18, 'PAR0006', '$2a$10$Mg8NB63xR8Xy1O2TuIw0b.wfNT8ydlaYRrIPgMj9qrK2BDYINXNnS', 'Six Parent', 6, 'sponsors/6.jpg', 1, 'PAR_USERS', 1, 1, '2015-05-14 08:56:08', '2015-05-20 11:23:35');

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
,`weekly_weight_point` decimal(4,1)
,`weekly_report_no` int(11)
,`weekly_weight_percent` int(11)
,`report_description` text
,`submission_date` date
,`weekly_report_setup_id` int(11) unsigned
,`weekly_report` int(11)
,`ca_weight_point` int(10) unsigned
,`exam_weight_point` int(10) unsigned
,`sponsor_id` int(11)
,`image_url` varchar(50)
,`sponsor_no` varchar(10)
,`mobile_number1` varchar(20)
,`email` varchar(100)
,`sponsor_name` varchar(101)
,`subject_id` int(3)
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
-- Table structure for table `weekly_detail_setups`
--

DROP TABLE IF EXISTS `weekly_detail_setups`;
CREATE TABLE IF NOT EXISTS `weekly_detail_setups` (
`weekly_detail_setup_id` int(11) NOT NULL,
  `weekly_report_setup_id` int(11) NOT NULL,
  `weekly_report_no` int(11) NOT NULL,
  `weekly_weight_point` decimal(4,1) NOT NULL DEFAULT '0.0',
  `weekly_weight_percent` int(11) NOT NULL DEFAULT '0',
  `submission_date` date NOT NULL,
  `report_description` text
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=15 ;

--
-- Dumping data for table `weekly_detail_setups`
--

INSERT INTO `weekly_detail_setups` (`weekly_detail_setup_id`, `weekly_report_setup_id`, `weekly_report_no`, `weekly_weight_point`, `weekly_weight_percent`, `submission_date`, `report_description`) VALUES
(1, 1, 1, '10.0', 10, '2015-05-22', 'CA 1'),
(2, 1, 2, '10.0', 10, '2015-05-29', 'CA 2'),
(3, 1, 3, '15.0', 25, '2015-06-05', 'MID TERM 1'),
(4, 1, 4, '10.0', 10, '2015-06-12', 'CA 4'),
(5, 1, 5, '15.0', 25, '2015-06-19', 'MID TERM 2'),
(6, 1, 6, '10.0', 10, '2015-06-26', 'CA 6'),
(7, 1, 7, '10.0', 10, '2015-07-03', 'CA 7'),
(8, 2, 1, '10.0', 10, '2015-05-22', 'CA 1'),
(9, 2, 2, '10.0', 10, '2015-05-29', 'CA 2'),
(10, 2, 3, '15.0', 25, '2015-06-05', 'MID TERM 1'),
(11, 2, 4, '10.0', 10, '2015-06-12', 'CA 4'),
(12, 2, 5, '15.0', 25, '2015-06-19', 'MID TERM 2'),
(13, 2, 6, '10.0', 10, '2015-06-26', 'CA 6'),
(14, 2, 7, '10.0', 10, '2015-07-03', 'CA 7');

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=206 ;

--
-- Dumping data for table `weekly_reports`
--

INSERT INTO `weekly_reports` (`weekly_report_id`, `subject_classlevel_id`, `weekly_detail_setup_id`, `marked_status`, `notification_status`) VALUES
(1, 4, 1, 1, 2),
(2, 4, 2, 1, 2),
(3, 5, 1, 2, 2),
(4, 5, 2, 1, 2),
(5, 5, 3, 1, 2),
(6, 5, 4, 1, 2),
(7, 4, 3, 1, 2),
(8, 5, 5, 1, 2),
(9, 5, 6, 1, 2),
(10, 4, 4, 1, 2),
(11, 4, 5, 1, 2),
(12, 5, 7, 1, 2),
(13, 4, 6, 1, 2),
(14, 4, 7, 1, 2),
(15, 6, 1, 1, 2),
(16, 6, 2, 1, 2),
(17, 7, 1, 1, 2),
(18, 6, 3, 1, 2),
(19, 7, 2, 1, 2),
(20, 6, 4, 1, 2),
(21, 6, 5, 1, 2),
(22, 6, 6, 1, 2),
(23, 6, 7, 1, 2),
(24, 11, 1, 1, 2),
(25, 11, 2, 1, 2),
(26, 11, 3, 1, 2),
(27, 11, 4, 1, 2),
(28, 11, 5, 1, 2),
(29, 12, 1, 1, 2),
(30, 11, 6, 1, 2),
(31, 12, 2, 1, 2),
(32, 11, 7, 1, 2),
(33, 12, 3, 1, 2),
(34, 12, 4, 1, 2),
(35, 18, 8, 1, 2),
(36, 12, 5, 1, 2),
(37, 18, 9, 1, 2),
(38, 18, 10, 1, 2),
(39, 18, 11, 1, 2),
(40, 18, 12, 1, 2),
(41, 18, 13, 1, 2),
(42, 18, 14, 1, 2),
(43, 21, 8, 1, 2),
(44, 21, 9, 1, 2),
(45, 21, 10, 1, 2),
(46, 21, 11, 1, 2),
(47, 12, 6, 1, 2),
(48, 21, 12, 1, 2),
(49, 12, 7, 1, 2),
(50, 20, 8, 1, 2),
(51, 21, 13, 1, 2),
(52, 21, 14, 1, 2),
(53, 20, 9, 1, 2),
(54, 20, 10, 1, 2),
(55, 26, 8, 1, 2),
(56, 20, 11, 1, 2),
(57, 20, 12, 1, 2),
(58, 20, 13, 1, 2),
(59, 26, 9, 1, 2),
(60, 20, 14, 1, 2),
(61, 26, 10, 1, 2),
(62, 22, 8, 1, 2),
(63, 22, 9, 1, 2),
(64, 22, 10, 1, 2),
(65, 22, 11, 1, 2),
(66, 22, 12, 1, 2),
(67, 22, 13, 1, 2),
(68, 22, 14, 1, 2),
(69, 26, 11, 1, 2),
(70, 27, 8, 1, 2),
(71, 27, 9, 1, 2),
(72, 27, 10, 1, 2),
(73, 27, 11, 1, 2),
(74, 26, 12, 1, 2),
(75, 27, 12, 1, 2),
(76, 26, 13, 1, 2),
(77, 27, 13, 1, 2),
(78, 27, 14, 1, 2),
(79, 26, 14, 1, 2),
(80, 3, 1, 2, 2),
(81, 3, 2, 1, 2),
(82, 3, 3, 1, 2),
(83, 3, 4, 1, 2),
(84, 3, 5, 1, 2),
(85, 3, 6, 1, 2),
(86, 3, 7, 1, 2),
(87, 8, 1, 1, 2),
(88, 8, 2, 1, 2),
(89, 8, 3, 1, 2),
(90, 8, 4, 1, 2),
(91, 2, 1, 1, 2),
(92, 8, 5, 1, 2),
(93, 2, 2, 1, 2),
(94, 8, 6, 1, 2),
(95, 2, 3, 1, 2),
(96, 2, 4, 1, 2),
(97, 8, 7, 1, 2),
(98, 2, 5, 1, 2),
(99, 2, 6, 1, 2),
(100, 2, 7, 1, 2),
(101, 15, 1, 1, 2),
(102, 10, 1, 1, 2),
(103, 10, 2, 1, 2),
(104, 15, 2, 1, 2),
(105, 15, 3, 1, 2),
(106, 15, 4, 1, 2),
(107, 15, 5, 1, 2),
(108, 10, 3, 1, 2),
(109, 10, 4, 1, 2),
(110, 15, 6, 1, 2),
(111, 10, 5, 1, 2),
(112, 15, 7, 1, 2),
(113, 10, 6, 1, 2),
(114, 10, 7, 1, 2),
(115, 16, 8, 1, 2),
(116, 14, 1, 1, 2),
(117, 14, 2, 1, 2),
(118, 14, 3, 1, 2),
(119, 14, 4, 1, 2),
(120, 14, 5, 1, 2),
(121, 16, 9, 1, 2),
(122, 16, 10, 1, 2),
(123, 14, 6, 1, 2),
(124, 14, 7, 1, 2),
(125, 16, 11, 1, 2),
(126, 16, 12, 1, 2),
(127, 17, 8, 1, 2),
(128, 16, 13, 1, 2),
(129, 17, 9, 1, 2),
(130, 17, 10, 1, 2),
(131, 17, 11, 1, 2),
(132, 16, 14, 1, 2),
(133, 17, 12, 1, 2),
(134, 17, 13, 1, 2),
(135, 17, 14, 1, 2),
(136, 23, 8, 1, 2),
(137, 23, 9, 1, 2),
(138, 23, 10, 1, 2),
(139, 23, 11, 1, 2),
(140, 23, 12, 1, 2),
(141, 23, 13, 1, 2),
(142, 23, 14, 1, 2),
(143, 28, 8, 1, 2),
(144, 28, 9, 1, 2),
(145, 28, 10, 1, 2),
(146, 28, 11, 1, 2),
(147, 28, 12, 1, 2),
(148, 28, 13, 1, 2),
(149, 28, 14, 1, 2),
(150, 1, 1, 1, 2),
(151, 1, 2, 1, 2),
(152, 1, 3, 2, 2),
(153, 1, 4, 1, 2),
(154, 1, 5, 1, 2),
(155, 1, 6, 1, 2),
(156, 1, 7, 1, 2),
(157, 9, 1, 1, 2),
(158, 9, 2, 1, 2),
(159, 9, 3, 1, 2),
(160, 9, 4, 1, 2),
(161, 9, 5, 1, 2),
(162, 9, 6, 1, 2),
(163, 9, 7, 1, 2),
(164, 30, 8, 1, 2),
(165, 13, 1, 1, 2),
(166, 30, 9, 1, 2),
(167, 30, 10, 1, 2),
(168, 13, 2, 1, 2),
(169, 24, 8, 1, 2),
(170, 13, 3, 1, 2),
(171, 24, 9, 1, 2),
(172, 24, 10, 1, 2),
(173, 13, 4, 1, 2),
(174, 24, 11, 1, 2),
(175, 24, 12, 1, 2),
(176, 24, 13, 1, 2),
(177, 13, 5, 1, 2),
(178, 24, 14, 1, 2),
(179, 13, 6, 1, 2),
(180, 30, 11, 1, 2),
(181, 30, 12, 1, 2),
(182, 13, 7, 1, 2),
(183, 30, 13, 1, 2),
(184, 30, 14, 1, 2),
(185, 19, 8, 1, 2),
(186, 19, 9, 1, 2),
(187, 19, 10, 1, 2),
(188, 19, 11, 1, 2),
(189, 19, 12, 1, 2),
(190, 19, 13, 1, 2),
(191, 19, 14, 1, 2),
(192, 25, 8, 1, 2),
(193, 25, 9, 1, 2),
(194, 25, 10, 1, 2),
(195, 25, 11, 1, 2),
(196, 25, 12, 1, 2),
(197, 25, 13, 1, 2),
(198, 25, 14, 1, 2),
(199, 29, 8, 1, 2),
(200, 29, 9, 1, 2),
(201, 29, 10, 1, 2),
(202, 29, 11, 1, 2),
(203, 29, 12, 1, 2),
(204, 29, 13, 1, 2),
(205, 29, 14, 1, 2);

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1441 ;

--
-- Dumping data for table `weekly_report_details`
--

INSERT INTO `weekly_report_details` (`weekly_report_detail_id`, `weekly_report_id`, `student_id`, `weekly_ca`) VALUES
(1, 1, 1, '6.0'),
(2, 1, 7, '9.0'),
(3, 1, 13, '8.0'),
(4, 1, 15, '10.0'),
(5, 1, 25, '7.0'),
(8, 2, 1, '10.0'),
(9, 2, 7, '8.0'),
(10, 2, 13, '4.0'),
(11, 2, 15, '3.0'),
(12, 2, 25, '9.0'),
(15, 3, 1, '10.0'),
(16, 3, 7, '7.0'),
(17, 3, 13, '8.0'),
(18, 3, 15, '6.0'),
(19, 3, 25, '9.0'),
(22, 4, 1, '7.0'),
(23, 4, 7, '9.0'),
(24, 4, 13, '8.0'),
(25, 4, 15, '10.0'),
(26, 4, 25, '6.0'),
(29, 5, 1, '9.0'),
(30, 5, 7, '7.0'),
(31, 5, 13, '14.0'),
(32, 5, 15, '10.0'),
(33, 5, 25, '15.0'),
(36, 6, 1, '3.0'),
(37, 6, 7, '7.0'),
(38, 6, 13, '8.0'),
(39, 6, 15, '6.0'),
(40, 6, 25, '3.0'),
(43, 7, 1, '14.5'),
(44, 7, 7, '11.0'),
(45, 7, 13, '7.0'),
(46, 7, 15, '11.0'),
(47, 7, 25, '9.0'),
(50, 8, 1, '12.0'),
(51, 8, 7, '12.0'),
(52, 8, 13, '13.0'),
(53, 8, 15, '15.0'),
(54, 8, 25, '10.0'),
(57, 9, 1, '6.0'),
(58, 9, 7, '8.0'),
(59, 9, 13, '6.0'),
(60, 9, 15, '10.0'),
(61, 9, 25, '7.0'),
(64, 10, 1, '6.5'),
(65, 10, 7, '9.0'),
(66, 10, 13, '10.0'),
(67, 10, 15, '10.0'),
(68, 10, 25, '6.0'),
(71, 11, 1, '8.0'),
(72, 11, 7, '11.0'),
(73, 11, 13, '15.0'),
(74, 11, 15, '9.0'),
(75, 11, 25, '10.0'),
(78, 12, 1, '8.0'),
(79, 12, 7, '7.0'),
(80, 12, 13, '9.0'),
(81, 12, 15, '8.0'),
(82, 12, 25, '5.0'),
(85, 13, 1, '7.5'),
(86, 13, 7, '9.0'),
(87, 13, 13, '5.5'),
(88, 13, 15, '10.0'),
(89, 13, 25, '4.5'),
(92, 14, 1, '7.0'),
(93, 14, 7, '9.0'),
(94, 14, 13, '10.0'),
(95, 14, 15, '10.0'),
(96, 14, 25, '8.0'),
(99, 15, 2, '9.0'),
(100, 15, 8, '9.0'),
(101, 15, 14, '6.0'),
(102, 15, 16, '10.0'),
(103, 15, 26, '7.5'),
(106, 16, 2, '5.0'),
(107, 16, 8, '5.0'),
(108, 16, 14, '9.0'),
(109, 16, 16, '7.5'),
(110, 16, 26, '5.0'),
(113, 17, 2, '7.0'),
(114, 17, 8, '5.0'),
(115, 17, 14, '9.0'),
(116, 17, 16, '9.0'),
(117, 17, 26, '8.0'),
(120, 18, 2, '14.0'),
(121, 18, 8, '10.0'),
(122, 18, 14, '7.0'),
(123, 18, 16, '15.0'),
(124, 18, 26, '14.5'),
(127, 19, 2, '0.0'),
(128, 19, 8, '0.0'),
(129, 19, 14, '0.0'),
(130, 19, 16, '0.0'),
(131, 19, 26, '0.0'),
(134, 20, 2, '9.5'),
(135, 20, 8, '10.0'),
(136, 20, 14, '8.0'),
(137, 20, 16, '6.5'),
(138, 20, 26, '10.0'),
(141, 21, 2, '11.0'),
(142, 21, 8, '12.0'),
(143, 21, 14, '13.0'),
(144, 21, 16, '13.0'),
(145, 21, 26, '11.0'),
(148, 22, 2, '9.0'),
(149, 22, 8, '9.0'),
(150, 22, 14, '10.0'),
(151, 22, 16, '9.5'),
(152, 22, 26, '8.0'),
(155, 23, 2, '10.0'),
(156, 23, 8, '10.0'),
(157, 23, 14, '5.5'),
(158, 23, 16, '5.5'),
(159, 23, 26, '10.0'),
(162, 24, 3, '9.0'),
(163, 24, 12, '3.5'),
(164, 24, 17, '5.0'),
(165, 24, 19, '8.0'),
(166, 24, 27, '4.0'),
(167, 24, 28, '9.0'),
(169, 25, 3, '9.0'),
(170, 25, 12, '7.0'),
(171, 25, 17, '9.0'),
(172, 25, 19, '9.0'),
(173, 25, 27, '8.0'),
(174, 25, 28, '9.0'),
(176, 26, 3, '13.0'),
(177, 26, 12, '11.0'),
(178, 26, 17, '12.0'),
(179, 26, 19, '10.5'),
(180, 26, 27, '11.0'),
(181, 26, 28, '15.0'),
(183, 27, 3, '9.0'),
(184, 27, 12, '10.0'),
(185, 27, 17, '8.0'),
(186, 27, 19, '4.5'),
(187, 27, 27, '10.0'),
(188, 27, 28, '10.0'),
(190, 28, 3, '5.5'),
(191, 28, 12, '6.0'),
(192, 28, 17, '6.5'),
(193, 28, 19, '4.5'),
(194, 28, 27, '7.0'),
(195, 28, 28, '5.5'),
(197, 29, 3, '7.0'),
(198, 29, 12, '7.0'),
(199, 29, 17, '8.0'),
(200, 29, 19, '8.0'),
(201, 29, 27, '9.0'),
(202, 29, 28, '6.0'),
(204, 30, 3, '8.0'),
(205, 30, 12, '6.5'),
(206, 30, 17, '8.0'),
(207, 30, 19, '10.0'),
(208, 30, 27, '8.0'),
(209, 30, 28, '8.0'),
(211, 31, 3, '8.0'),
(212, 31, 12, '6.0'),
(213, 31, 17, '9.0'),
(214, 31, 19, '9.0'),
(215, 31, 27, '7.0'),
(216, 31, 28, '7.0'),
(218, 32, 3, '10.0'),
(219, 32, 12, '10.0'),
(220, 32, 17, '10.0'),
(221, 32, 19, '10.0'),
(222, 32, 27, '10.0'),
(223, 32, 28, '10.0'),
(225, 33, 3, '8.0'),
(226, 33, 12, '15.0'),
(227, 33, 17, '7.0'),
(228, 33, 19, '9.0'),
(229, 33, 27, '12.0'),
(230, 33, 28, '9.0'),
(232, 34, 3, '8.0'),
(233, 34, 12, '8.0'),
(234, 34, 17, '9.0'),
(235, 34, 19, '9.0'),
(236, 34, 27, '7.0'),
(237, 34, 28, '0.0'),
(239, 35, 9, '8.5'),
(240, 35, 18, '5.5'),
(241, 35, 22, '10.0'),
(242, 35, 29, '1.0'),
(246, 36, 3, '8.0'),
(247, 36, 12, '8.0'),
(248, 36, 17, '7.0'),
(249, 36, 19, '7.0'),
(250, 36, 27, '9.0'),
(251, 36, 28, '9.0'),
(253, 37, 9, '7.5'),
(254, 37, 18, '7.5'),
(255, 37, 22, '9.5'),
(256, 37, 29, '5.5'),
(260, 38, 9, '10.0'),
(261, 38, 18, '10.0'),
(262, 38, 22, '10.0'),
(263, 38, 29, '10.0'),
(267, 39, 9, '5.5'),
(268, 39, 18, '7.5'),
(269, 39, 22, '9.0'),
(270, 39, 29, '9.0'),
(274, 40, 9, '9.0'),
(275, 40, 18, '9.0'),
(276, 40, 22, '15.0'),
(277, 40, 29, '13.0'),
(281, 41, 9, '6.0'),
(282, 41, 18, '9.0'),
(283, 41, 22, '8.0'),
(284, 41, 29, '9.0'),
(288, 42, 9, '8.0'),
(289, 42, 18, '8.0'),
(290, 42, 22, '9.0'),
(291, 42, 29, '8.0'),
(295, 43, 5, '7.0'),
(296, 43, 10, '8.0'),
(297, 43, 20, '5.0'),
(298, 43, 23, '9.0'),
(299, 43, 30, '3.0'),
(302, 44, 5, '5.0'),
(303, 44, 10, '0.5'),
(304, 44, 20, '5.0'),
(305, 44, 23, '8.5'),
(306, 44, 30, '5.0'),
(309, 45, 5, '14.0'),
(310, 45, 10, '12.0'),
(311, 45, 20, '8.5'),
(312, 45, 23, '13.0'),
(313, 45, 30, '9.0'),
(316, 46, 5, '9.0'),
(317, 46, 10, '9.0'),
(318, 46, 20, '9.0'),
(319, 46, 23, '10.0'),
(320, 46, 30, '9.0'),
(323, 47, 3, '8.0'),
(324, 47, 12, '6.0'),
(325, 47, 17, '9.0'),
(326, 47, 19, '9.0'),
(327, 47, 27, '7.0'),
(328, 47, 28, '7.0'),
(330, 48, 5, '12.0'),
(331, 48, 10, '9.0'),
(332, 48, 20, '11.0'),
(333, 48, 23, '11.0'),
(334, 48, 30, '12.0'),
(337, 49, 3, '8.0'),
(338, 49, 12, '8.0'),
(339, 49, 17, '7.0'),
(340, 49, 19, '9.0'),
(341, 49, 27, '5.0'),
(342, 49, 28, '9.0'),
(344, 50, 9, '9.0'),
(345, 50, 18, '7.0'),
(346, 50, 22, '9.0'),
(347, 50, 29, '8.0'),
(351, 51, 5, '10.0'),
(352, 51, 10, '10.0'),
(353, 51, 20, '9.0'),
(354, 51, 23, '10.0'),
(355, 51, 30, '9.0'),
(358, 52, 5, '9.0'),
(359, 52, 10, '10.0'),
(360, 52, 20, '10.0'),
(361, 52, 23, '10.0'),
(362, 52, 30, '9.0'),
(365, 53, 9, '9.0'),
(366, 53, 18, '7.0'),
(367, 53, 22, '8.0'),
(368, 53, 29, '9.0'),
(372, 54, 9, '9.0'),
(373, 54, 18, '7.0'),
(374, 54, 22, '9.0'),
(375, 54, 29, '8.0'),
(379, 55, 6, '10.0'),
(380, 55, 11, '10.0'),
(381, 55, 21, '10.0'),
(382, 55, 24, '10.0'),
(383, 55, 31, '9.0'),
(386, 56, 9, '9.0'),
(387, 56, 18, '6.0'),
(388, 56, 22, '8.0'),
(389, 56, 29, '7.0'),
(393, 57, 9, '14.0'),
(394, 57, 18, '14.0'),
(395, 57, 22, '14.0'),
(396, 57, 29, '12.0'),
(400, 58, 9, '9.0'),
(401, 58, 18, '7.0'),
(402, 58, 22, '7.0'),
(403, 58, 29, '8.0'),
(407, 59, 6, '9.5'),
(408, 59, 11, '5.5'),
(409, 59, 21, '9.0'),
(410, 59, 24, '7.0'),
(411, 59, 31, '8.0'),
(414, 60, 9, '9.0'),
(415, 60, 18, '7.0'),
(416, 60, 22, '8.0'),
(417, 60, 29, '9.0'),
(421, 61, 6, '11.0'),
(422, 61, 11, '15.0'),
(423, 61, 21, '12.0'),
(424, 61, 24, '14.0'),
(425, 61, 31, '13.0'),
(428, 62, 5, '8.0'),
(429, 62, 10, '9.0'),
(430, 62, 20, '8.0'),
(431, 62, 23, '7.0'),
(432, 62, 30, '7.0'),
(435, 63, 5, '0.0'),
(436, 63, 10, '8.0'),
(437, 63, 20, '8.0'),
(438, 63, 23, '2.0'),
(439, 63, 30, '7.0'),
(442, 64, 5, '6.0'),
(443, 64, 10, '5.0'),
(444, 64, 20, '7.0'),
(445, 64, 23, '9.0'),
(446, 64, 30, '8.0'),
(449, 65, 5, '6.0'),
(450, 65, 10, '3.0'),
(451, 65, 20, '8.0'),
(452, 65, 23, '4.0'),
(453, 65, 30, '9.0'),
(456, 66, 5, '7.0'),
(457, 66, 10, '8.0'),
(458, 66, 20, '9.0'),
(459, 66, 23, '7.0'),
(460, 66, 30, '8.0'),
(463, 67, 5, '5.0'),
(464, 67, 10, '7.0'),
(465, 67, 20, '9.0'),
(466, 67, 23, '5.0'),
(467, 67, 30, '1.0'),
(470, 68, 5, '9.0'),
(471, 68, 10, '6.0'),
(472, 68, 20, '8.0'),
(473, 68, 23, '8.0'),
(474, 68, 30, '7.0'),
(477, 69, 6, '8.0'),
(478, 69, 11, '9.0'),
(479, 69, 21, '10.0'),
(480, 69, 24, '9.0'),
(481, 69, 31, '9.0'),
(484, 70, 6, '6.0'),
(485, 70, 11, '7.0'),
(486, 70, 21, '8.0'),
(487, 70, 24, '9.0'),
(488, 70, 31, '8.0'),
(491, 71, 6, '6.0'),
(492, 71, 11, '9.0'),
(493, 71, 21, '8.0'),
(494, 71, 24, '7.0'),
(495, 71, 31, '9.0'),
(498, 72, 6, '8.0'),
(499, 72, 11, '9.0'),
(500, 72, 21, '9.0'),
(501, 72, 24, '6.0'),
(502, 72, 31, '8.0'),
(505, 73, 6, '2.0'),
(506, 73, 11, '9.0'),
(507, 73, 21, '9.0'),
(508, 73, 24, '6.0'),
(509, 73, 31, '8.0'),
(512, 74, 6, '13.0'),
(513, 74, 11, '14.0'),
(514, 74, 21, '12.0'),
(515, 74, 24, '12.0'),
(516, 74, 31, '12.0'),
(519, 75, 6, '4.0'),
(520, 75, 11, '9.0'),
(521, 75, 21, '7.0'),
(522, 75, 24, '6.0'),
(523, 75, 31, '9.0'),
(526, 76, 6, '8.0'),
(527, 76, 11, '7.5'),
(528, 76, 21, '9.0'),
(529, 76, 24, '7.0'),
(530, 76, 31, '9.0'),
(533, 77, 6, '4.0'),
(534, 77, 11, '7.0'),
(535, 77, 21, '9.0'),
(536, 77, 24, '9.0'),
(537, 77, 31, '8.0'),
(540, 78, 6, '3.0'),
(541, 78, 11, '8.0'),
(542, 78, 21, '9.0'),
(543, 78, 24, '5.0'),
(544, 78, 31, '6.0'),
(547, 79, 6, '9.0'),
(548, 79, 11, '9.0'),
(549, 79, 21, '8.0'),
(550, 79, 24, '10.0'),
(551, 79, 31, '10.0'),
(554, 80, 1, '10.0'),
(555, 80, 7, '10.0'),
(556, 80, 13, '9.5'),
(557, 80, 15, '10.0'),
(558, 80, 25, '9.5'),
(561, 81, 1, '9.5'),
(562, 81, 7, '10.0'),
(563, 81, 13, '10.0'),
(564, 81, 15, '4.5'),
(565, 81, 25, '3.5'),
(568, 82, 1, '13.0'),
(569, 82, 7, '9.0'),
(570, 82, 13, '9.0'),
(571, 82, 15, '9.0'),
(572, 82, 25, '9.0'),
(575, 83, 1, '9.0'),
(576, 83, 7, '5.5'),
(577, 83, 13, '5.5'),
(578, 83, 15, '9.0'),
(579, 83, 25, '8.0'),
(582, 84, 1, '15.0'),
(583, 84, 7, '13.0'),
(584, 84, 13, '13.0'),
(585, 84, 15, '15.0'),
(586, 84, 25, '14.0'),
(589, 85, 1, '7.0'),
(590, 85, 7, '4.0'),
(591, 85, 13, '5.0'),
(592, 85, 15, '10.0'),
(593, 85, 25, '6.0'),
(596, 86, 1, '8.0'),
(597, 86, 7, '8.0'),
(598, 86, 13, '7.0'),
(599, 86, 15, '8.0'),
(600, 86, 25, '8.0'),
(603, 87, 2, '9.0'),
(604, 87, 8, '9.0'),
(605, 87, 14, '9.0'),
(606, 87, 16, '9.0'),
(607, 87, 26, '9.0'),
(610, 88, 2, '6.0'),
(611, 88, 8, '7.0'),
(612, 88, 14, '6.0'),
(613, 88, 16, '3.0'),
(614, 88, 26, '8.0'),
(617, 89, 2, '9.0'),
(618, 89, 8, '3.0'),
(619, 89, 14, '11.0'),
(620, 89, 16, '3.0'),
(621, 89, 26, '5.0'),
(624, 90, 2, '9.0'),
(625, 90, 8, '9.0'),
(626, 90, 14, '5.0'),
(627, 90, 16, '9.0'),
(628, 90, 26, '9.0'),
(631, 91, 1, '6.0'),
(632, 91, 7, '7.0'),
(633, 91, 13, '8.0'),
(634, 91, 15, '8.0'),
(635, 91, 25, '9.0'),
(638, 92, 2, '11.0'),
(639, 92, 8, '10.0'),
(640, 92, 14, '13.0'),
(641, 92, 16, '11.0'),
(642, 92, 26, '10.0'),
(645, 93, 1, '8.0'),
(646, 93, 7, '7.0'),
(647, 93, 13, '6.0'),
(648, 93, 15, '8.0'),
(649, 93, 25, '8.0'),
(652, 94, 2, '4.0'),
(653, 94, 8, '9.0'),
(654, 94, 14, '3.0'),
(655, 94, 16, '8.0'),
(656, 94, 26, '3.0'),
(659, 95, 1, '9.0'),
(660, 95, 7, '7.0'),
(661, 95, 13, '8.0'),
(662, 95, 15, '8.0'),
(663, 95, 25, '6.0'),
(666, 96, 1, '6.0'),
(667, 96, 7, '8.0'),
(668, 96, 13, '7.0'),
(669, 96, 15, '9.0'),
(670, 96, 25, '9.0'),
(673, 97, 2, '10.0'),
(674, 97, 8, '10.0'),
(675, 97, 14, '10.0'),
(676, 97, 16, '10.0'),
(677, 97, 26, '10.0'),
(680, 98, 1, '8.0'),
(681, 98, 7, '7.0'),
(682, 98, 13, '6.0'),
(683, 98, 15, '7.0'),
(684, 98, 25, '9.0'),
(687, 99, 1, '5.0'),
(688, 99, 7, '7.0'),
(689, 99, 13, '6.0'),
(690, 99, 15, '8.0'),
(691, 99, 25, '9.0'),
(694, 100, 1, '6.0'),
(695, 100, 7, '6.0'),
(696, 100, 13, '8.0'),
(697, 100, 15, '7.0'),
(698, 100, 25, '9.0'),
(701, 101, 3, '9.0'),
(702, 101, 12, '2.0'),
(703, 101, 17, '9.0'),
(704, 101, 19, '3.0'),
(705, 101, 27, '2.0'),
(706, 101, 28, '7.0'),
(708, 102, 2, '9.0'),
(709, 102, 8, '7.0'),
(710, 102, 14, '9.0'),
(711, 102, 16, '6.0'),
(712, 102, 26, '8.0'),
(715, 103, 2, '9.0'),
(716, 103, 8, '8.0'),
(717, 103, 14, '8.0'),
(718, 103, 16, '7.0'),
(719, 103, 26, '8.0'),
(722, 104, 3, '6.0'),
(723, 104, 12, '10.0'),
(724, 104, 17, '7.0'),
(725, 104, 19, '9.0'),
(726, 104, 27, '9.0'),
(727, 104, 28, '3.0'),
(729, 105, 3, '13.0'),
(730, 105, 12, '11.0'),
(731, 105, 17, '12.0'),
(732, 105, 19, '11.0'),
(733, 105, 27, '11.0'),
(734, 105, 28, '14.0'),
(736, 106, 3, '9.0'),
(737, 106, 12, '10.0'),
(738, 106, 17, '9.0'),
(739, 106, 19, '10.0'),
(740, 106, 27, '8.0'),
(741, 106, 28, '10.0'),
(743, 107, 3, '12.0'),
(744, 107, 12, '12.0'),
(745, 107, 17, '11.0'),
(746, 107, 19, '6.5'),
(747, 107, 27, '12.0'),
(748, 107, 28, '14.0'),
(750, 108, 2, '7.0'),
(751, 108, 8, '6.0'),
(752, 108, 14, '7.0'),
(753, 108, 16, '9.0'),
(754, 108, 26, '8.0'),
(757, 109, 2, '9.0'),
(758, 109, 8, '1.0'),
(759, 109, 14, '5.0'),
(760, 109, 16, '5.0'),
(761, 109, 26, '8.0'),
(764, 110, 3, '0.0'),
(765, 110, 12, '7.0'),
(766, 110, 17, '0.0'),
(767, 110, 19, '9.0'),
(768, 110, 27, '8.0'),
(769, 110, 28, '6.0'),
(771, 111, 2, '9.0'),
(772, 111, 8, '1.0'),
(773, 111, 14, '7.0'),
(774, 111, 16, '8.0'),
(775, 111, 26, '5.0'),
(778, 112, 3, '10.0'),
(779, 112, 12, '10.0'),
(780, 112, 17, '10.0'),
(781, 112, 19, '9.0'),
(782, 112, 27, '10.0'),
(783, 112, 28, '10.0'),
(785, 113, 2, '9.0'),
(786, 113, 8, '1.0'),
(787, 113, 14, '3.0'),
(788, 113, 16, '5.0'),
(789, 113, 26, '8.0'),
(792, 114, 2, '9.0'),
(793, 114, 8, '1.0'),
(794, 114, 14, '4.0'),
(795, 114, 16, '5.0'),
(796, 114, 26, '8.0'),
(799, 115, 9, '4.0'),
(800, 115, 18, '1.0'),
(801, 115, 22, '9.0'),
(802, 115, 29, '0.0'),
(806, 116, 3, '6.0'),
(807, 116, 12, '6.0'),
(808, 116, 17, '7.0'),
(809, 116, 19, '5.0'),
(810, 116, 27, '9.0'),
(811, 116, 28, '3.0'),
(813, 117, 3, '9.0'),
(814, 117, 12, '7.0'),
(815, 117, 17, '8.0'),
(816, 117, 19, '9.0'),
(817, 117, 27, '9.0'),
(818, 117, 28, '2.0'),
(820, 118, 3, '9.0'),
(821, 118, 12, '9.0'),
(822, 118, 17, '7.0'),
(823, 118, 19, '8.0'),
(824, 118, 27, '6.0'),
(825, 118, 28, '8.0'),
(827, 119, 3, '9.0'),
(828, 119, 12, '6.0'),
(829, 119, 17, '7.0'),
(830, 119, 19, '5.0'),
(831, 119, 27, '9.0'),
(832, 119, 28, '0.0'),
(834, 120, 3, '7.0'),
(835, 120, 12, '9.0'),
(836, 120, 17, '9.0'),
(837, 120, 19, '7.0'),
(838, 120, 27, '8.0'),
(839, 120, 28, '1.0'),
(841, 121, 9, '9.0'),
(842, 121, 18, '9.0'),
(843, 121, 22, '9.0'),
(844, 121, 29, '9.0'),
(848, 122, 9, '13.0'),
(849, 122, 18, '12.0'),
(850, 122, 22, '10.0'),
(851, 122, 29, '11.0'),
(855, 123, 3, '8.0'),
(856, 123, 12, '8.0'),
(857, 123, 17, '6.0'),
(858, 123, 19, '9.0'),
(859, 123, 27, '4.0'),
(860, 123, 28, '2.0'),
(862, 124, 3, '9.0'),
(863, 124, 12, '8.0'),
(864, 124, 17, '6.0'),
(865, 124, 19, '9.0'),
(866, 124, 27, '5.0'),
(867, 124, 28, '3.0'),
(869, 125, 9, '10.0'),
(870, 125, 18, '10.0'),
(871, 125, 22, '10.0'),
(872, 125, 29, '10.0'),
(876, 126, 9, '15.0'),
(877, 126, 18, '15.0'),
(878, 126, 22, '11.0'),
(879, 126, 29, '10.0'),
(883, 127, 9, '6.0'),
(884, 127, 18, '7.0'),
(885, 127, 22, '1.0'),
(886, 127, 29, '9.0'),
(890, 128, 9, '3.0'),
(891, 128, 18, '9.0'),
(892, 128, 22, '9.0'),
(893, 128, 29, '9.0'),
(897, 129, 9, '8.0'),
(898, 129, 18, '9.0'),
(899, 129, 22, '1.0'),
(900, 129, 29, '7.0'),
(904, 130, 9, '7.0'),
(905, 130, 18, '6.0'),
(906, 130, 22, '3.0'),
(907, 130, 29, '8.0'),
(911, 131, 9, '7.0'),
(912, 131, 18, '7.0'),
(913, 131, 22, '2.0'),
(914, 131, 29, '8.0'),
(918, 132, 9, '7.0'),
(919, 132, 18, '7.0'),
(920, 132, 22, '1.0'),
(921, 132, 29, '3.0'),
(925, 133, 9, '9.0'),
(926, 133, 18, '7.0'),
(927, 133, 22, '3.0'),
(928, 133, 29, '8.0'),
(932, 134, 9, '8.0'),
(933, 134, 18, '9.0'),
(934, 134, 22, '4.0'),
(935, 134, 29, '6.0'),
(939, 135, 9, '6.0'),
(940, 135, 18, '9.0'),
(941, 135, 22, '1.0'),
(942, 135, 29, '7.0'),
(946, 136, 5, '10.0'),
(947, 136, 10, '10.0'),
(948, 136, 20, '9.0'),
(949, 136, 23, '10.0'),
(950, 136, 30, '9.0'),
(953, 137, 5, '5.5'),
(954, 137, 10, '5.0'),
(955, 137, 20, '9.5'),
(956, 137, 23, '10.0'),
(957, 137, 30, '6.5'),
(960, 138, 5, '12.0'),
(961, 138, 10, '11.0'),
(962, 138, 20, '14.0'),
(963, 138, 23, '10.0'),
(964, 138, 30, '13.0'),
(967, 139, 5, '6.0'),
(968, 139, 10, '7.0'),
(969, 139, 20, '10.0'),
(970, 139, 23, '6.0'),
(971, 139, 30, '5.0'),
(974, 140, 5, '14.0'),
(975, 140, 10, '14.0'),
(976, 140, 20, '12.0'),
(977, 140, 23, '12.0'),
(978, 140, 30, '13.0'),
(981, 141, 5, '9.0'),
(982, 141, 10, '4.0'),
(983, 141, 20, '9.0'),
(984, 141, 23, '3.0'),
(985, 141, 30, '8.0'),
(988, 142, 5, '9.0'),
(989, 142, 10, '8.0'),
(990, 142, 20, '10.0'),
(991, 142, 23, '7.0'),
(992, 142, 30, '7.0'),
(995, 143, 6, '3.0'),
(996, 143, 11, '6.0'),
(997, 143, 21, '8.0'),
(998, 143, 24, '8.0'),
(999, 143, 31, '8.0'),
(1002, 144, 6, '7.0'),
(1003, 144, 11, '5.0'),
(1004, 144, 21, '10.0'),
(1005, 144, 24, '6.0'),
(1006, 144, 31, '7.0'),
(1009, 145, 6, '7.0'),
(1010, 145, 11, '7.0'),
(1011, 145, 21, '7.0'),
(1012, 145, 24, '6.0'),
(1013, 145, 31, '5.0'),
(1016, 146, 6, '4.0'),
(1017, 146, 11, '9.0'),
(1018, 146, 21, '7.0'),
(1019, 146, 24, '8.0'),
(1020, 146, 31, '8.0'),
(1023, 147, 6, '11.0'),
(1024, 147, 11, '10.0'),
(1025, 147, 21, '10.0'),
(1026, 147, 24, '13.0'),
(1027, 147, 31, '14.0'),
(1030, 148, 6, '9.0'),
(1031, 148, 11, '8.0'),
(1032, 148, 21, '8.0'),
(1033, 148, 24, '7.0'),
(1034, 148, 31, '4.0'),
(1037, 149, 6, '9.0'),
(1038, 149, 11, '8.0'),
(1039, 149, 21, '8.0'),
(1040, 149, 24, '7.0'),
(1041, 149, 31, '8.0'),
(1044, 150, 1, '5.0'),
(1045, 150, 7, '10.0'),
(1046, 150, 13, '7.0'),
(1047, 150, 15, '9.0'),
(1048, 150, 25, '6.0'),
(1051, 151, 1, '7.0'),
(1052, 151, 7, '2.0'),
(1053, 151, 13, '5.0'),
(1054, 151, 15, '10.0'),
(1055, 151, 25, '6.0'),
(1058, 152, 1, '9.0'),
(1059, 152, 7, '12.0'),
(1060, 152, 13, '13.0'),
(1061, 152, 15, '11.0'),
(1062, 152, 25, '9.0'),
(1065, 153, 1, '4.5'),
(1066, 153, 7, '6.0'),
(1067, 153, 13, '8.0'),
(1068, 153, 15, '7.0'),
(1069, 153, 25, '6.5'),
(1072, 154, 1, '7.0'),
(1073, 154, 7, '3.0'),
(1074, 154, 13, '4.0'),
(1075, 154, 15, '9.0'),
(1076, 154, 25, '5.0'),
(1079, 155, 1, '6.0'),
(1080, 155, 7, '7.0'),
(1081, 155, 13, '5.0'),
(1082, 155, 15, '9.0'),
(1083, 155, 25, '3.0'),
(1086, 156, 1, '6.0'),
(1087, 156, 7, '9.0'),
(1088, 156, 13, '9.0'),
(1089, 156, 15, '10.0'),
(1090, 156, 25, '5.0'),
(1093, 157, 2, '9.0'),
(1094, 157, 8, '6.0'),
(1095, 157, 14, '6.0'),
(1096, 157, 16, '7.0'),
(1097, 157, 26, '7.0'),
(1100, 158, 2, '5.0'),
(1101, 158, 8, '6.0'),
(1102, 158, 14, '7.0'),
(1103, 158, 16, '6.0'),
(1104, 158, 26, '5.0'),
(1107, 159, 2, '11.0'),
(1108, 159, 8, '9.0'),
(1109, 159, 14, '6.0'),
(1110, 159, 16, '10.0'),
(1111, 159, 26, '7.0'),
(1114, 160, 2, '7.0'),
(1115, 160, 8, '9.0'),
(1116, 160, 14, '6.0'),
(1117, 160, 16, '6.0'),
(1118, 160, 26, '9.0'),
(1121, 161, 2, '8.5'),
(1122, 161, 8, '13.0'),
(1123, 161, 14, '4.0'),
(1124, 161, 16, '6.5'),
(1125, 161, 26, '12.0'),
(1128, 162, 2, '8.0'),
(1129, 162, 8, '10.0'),
(1130, 162, 14, '6.0'),
(1131, 162, 16, '7.0'),
(1132, 162, 26, '9.0'),
(1135, 163, 2, '7.0'),
(1136, 163, 8, '10.0'),
(1137, 163, 14, '5.0'),
(1138, 163, 16, '8.0'),
(1139, 163, 26, '8.0'),
(1142, 164, 6, '9.0'),
(1143, 164, 11, '8.0'),
(1144, 164, 21, '2.0'),
(1145, 164, 24, '6.0'),
(1146, 164, 31, '4.0'),
(1149, 165, 3, '5.0'),
(1150, 165, 12, '5.0'),
(1151, 165, 17, '3.0'),
(1152, 165, 19, '9.0'),
(1153, 165, 27, '4.0'),
(1154, 165, 28, '9.0'),
(1156, 166, 6, '4.0'),
(1157, 166, 11, '5.0'),
(1158, 166, 21, '3.0'),
(1159, 166, 24, '8.0'),
(1160, 166, 31, '9.0'),
(1163, 167, 6, '5.0'),
(1164, 167, 11, '6.0'),
(1165, 167, 21, '8.0'),
(1166, 167, 24, '7.0'),
(1167, 167, 31, '9.0'),
(1170, 168, 3, '8.0'),
(1171, 168, 12, '7.0'),
(1172, 168, 17, '5.0'),
(1173, 168, 19, '9.0'),
(1174, 168, 27, '6.0'),
(1175, 168, 28, '7.0'),
(1177, 169, 5, '9.0'),
(1178, 169, 10, '6.0'),
(1179, 169, 20, '7.0'),
(1180, 169, 23, '4.0'),
(1181, 169, 30, '8.0'),
(1184, 170, 3, '5.0'),
(1185, 170, 12, '6.0'),
(1186, 170, 17, '9.0'),
(1187, 170, 19, '5.0'),
(1188, 170, 27, '10.0'),
(1189, 170, 28, '4.5'),
(1191, 171, 5, '5.0'),
(1192, 171, 10, '4.0'),
(1193, 171, 20, '7.0'),
(1194, 171, 23, '7.0'),
(1195, 171, 30, '8.0'),
(1198, 172, 5, '8.0'),
(1199, 172, 10, '5.0'),
(1200, 172, 20, '7.0'),
(1201, 172, 23, '8.0'),
(1202, 172, 30, '6.0'),
(1205, 173, 3, '9.0'),
(1206, 173, 12, '4.0'),
(1207, 173, 17, '8.0'),
(1208, 173, 19, '1.0'),
(1209, 173, 27, '7.0'),
(1210, 173, 28, '9.0'),
(1212, 174, 5, '4.0'),
(1213, 174, 10, '8.0'),
(1214, 174, 20, '7.0'),
(1215, 174, 23, '4.0'),
(1216, 174, 30, '5.0'),
(1219, 175, 5, '5.0'),
(1220, 175, 10, '4.0'),
(1221, 175, 20, '8.0'),
(1222, 175, 23, '8.0'),
(1223, 175, 30, '6.0'),
(1226, 176, 5, '7.0'),
(1227, 176, 10, '4.0'),
(1228, 176, 20, '5.0'),
(1229, 176, 23, '5.0'),
(1230, 176, 30, '6.0'),
(1233, 177, 3, '14.0'),
(1234, 177, 12, '10.0'),
(1235, 177, 17, '11.0'),
(1236, 177, 19, '11.0'),
(1237, 177, 27, '10.0'),
(1238, 177, 28, '8.0'),
(1240, 178, 5, '6.0'),
(1241, 178, 10, '5.0'),
(1242, 178, 20, '8.0'),
(1243, 178, 23, '9.0'),
(1244, 178, 30, '7.0'),
(1247, 179, 3, '9.0'),
(1248, 179, 12, '9.0'),
(1249, 179, 17, '8.0'),
(1250, 179, 19, '3.0'),
(1251, 179, 27, '5.0'),
(1252, 179, 28, '10.0'),
(1254, 180, 6, '8.0'),
(1255, 180, 11, '4.0'),
(1256, 180, 21, '7.0'),
(1257, 180, 24, '5.0'),
(1258, 180, 31, '6.0'),
(1261, 181, 6, '7.0'),
(1262, 181, 11, '6.0'),
(1263, 181, 21, '9.0'),
(1264, 181, 24, '7.0'),
(1265, 181, 31, '8.0'),
(1268, 182, 3, '8.0'),
(1269, 182, 12, '8.0'),
(1270, 182, 17, '9.0'),
(1271, 182, 19, '5.0'),
(1272, 182, 27, '8.0'),
(1273, 182, 28, '8.0'),
(1275, 183, 6, '5.0'),
(1276, 183, 11, '6.0'),
(1277, 183, 21, '7.0'),
(1278, 183, 24, '7.0'),
(1279, 183, 31, '8.0'),
(1282, 184, 6, '6.0'),
(1283, 184, 11, '7.0'),
(1284, 184, 21, '7.0'),
(1285, 184, 24, '9.0'),
(1286, 184, 31, '8.0'),
(1289, 185, 9, '5.0'),
(1290, 185, 18, '7.0'),
(1291, 185, 22, '9.0'),
(1292, 185, 29, '8.0'),
(1296, 186, 9, '6.0'),
(1297, 186, 18, '5.0'),
(1298, 186, 22, '9.0'),
(1299, 186, 29, '3.0'),
(1303, 187, 9, '10.0'),
(1304, 187, 18, '11.0'),
(1305, 187, 22, '14.0'),
(1306, 187, 29, '12.0'),
(1310, 188, 9, '6.0'),
(1311, 188, 18, '7.0'),
(1312, 188, 22, '10.0'),
(1313, 188, 29, '9.0'),
(1317, 189, 9, '11.0'),
(1318, 189, 18, '12.0'),
(1319, 189, 22, '11.0'),
(1320, 189, 29, '13.0'),
(1324, 190, 9, '5.0'),
(1325, 190, 18, '5.0'),
(1326, 190, 22, '9.0'),
(1327, 190, 29, '10.0'),
(1331, 191, 9, '7.0'),
(1332, 191, 18, '6.0'),
(1333, 191, 22, '5.0'),
(1334, 191, 29, '4.0'),
(1338, 192, 5, '8.0'),
(1339, 192, 10, '9.0'),
(1340, 192, 20, '8.0'),
(1341, 192, 23, '7.0'),
(1342, 192, 30, '7.0'),
(1345, 150, 4, '6.0'),
(1346, 151, 4, '7.0'),
(1347, 152, 4, '9.0'),
(1348, 153, 4, '5.0'),
(1349, 154, 4, '8.0'),
(1350, 155, 4, '8.0'),
(1351, 156, 4, '3.0'),
(1352, 193, 5, '7.0'),
(1353, 193, 10, '6.0'),
(1354, 193, 20, '8.0'),
(1355, 193, 23, '6.0'),
(1356, 193, 30, '8.0'),
(1359, 194, 5, '7.0'),
(1360, 194, 10, '8.0'),
(1361, 194, 20, '6.0'),
(1362, 194, 23, '4.0'),
(1363, 194, 30, '5.0'),
(1366, 195, 5, '5.0'),
(1367, 195, 10, '4.0'),
(1368, 195, 20, '7.0'),
(1369, 195, 23, '3.0'),
(1370, 195, 30, '8.0'),
(1373, 196, 5, '7.0'),
(1374, 196, 10, '6.0'),
(1375, 196, 20, '7.0'),
(1376, 196, 23, '5.0'),
(1377, 196, 30, '8.0'),
(1380, 197, 5, '4.0'),
(1381, 197, 10, '2.0'),
(1382, 197, 20, '7.0'),
(1383, 197, 23, '9.0'),
(1384, 197, 30, '5.0'),
(1387, 198, 5, '5.0'),
(1388, 198, 10, '4.0'),
(1389, 198, 20, '7.0'),
(1390, 198, 23, '9.0'),
(1391, 198, 30, '6.0'),
(1394, 199, 6, '9.0'),
(1395, 199, 11, '4.0'),
(1396, 199, 21, '8.0'),
(1397, 199, 24, '5.0'),
(1398, 199, 31, '6.0'),
(1401, 200, 6, '5.0'),
(1402, 200, 11, '9.0'),
(1403, 200, 21, '7.0'),
(1404, 200, 24, '8.0'),
(1405, 200, 31, '6.0'),
(1408, 201, 6, '8.0'),
(1409, 201, 11, '5.0'),
(1410, 201, 21, '8.0'),
(1411, 201, 24, '6.0'),
(1412, 201, 31, '7.0'),
(1415, 202, 6, '9.0'),
(1416, 202, 11, '8.0'),
(1417, 202, 21, '7.0'),
(1418, 202, 24, '5.0'),
(1419, 202, 31, '6.0'),
(1422, 203, 6, '8.0'),
(1423, 203, 11, '9.0'),
(1424, 203, 21, '8.0'),
(1425, 203, 24, '8.0'),
(1426, 203, 31, '9.0'),
(1429, 204, 6, '8.0'),
(1430, 204, 11, '5.0'),
(1431, 204, 21, '7.0'),
(1432, 204, 24, '6.0'),
(1433, 204, 31, '8.0'),
(1436, 205, 6, '6.0'),
(1437, 205, 11, '8.0'),
(1438, 205, 21, '7.0'),
(1439, 205, 24, '7.0'),
(1440, 205, 31, '6.0');

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
(1, 7, 1, 1),
(2, 7, 2, 1);

-- --------------------------------------------------------

--
-- Stand-in structure for view `weekly_setupviews`
--
DROP VIEW IF EXISTS `weekly_setupviews`;
CREATE TABLE IF NOT EXISTS `weekly_setupviews` (
`weekly_report_setup_id` int(11) unsigned
,`weekly_report` int(11)
,`weekly_weight_point` decimal(4,1)
,`weekly_weight_percent` int(11)
,`classgroup_id` int(11)
,`academic_term_id` int(11)
,`weekly_detail_setup_id` int(11)
,`weekly_report_no` int(11)
,`report_description` text
,`submission_date` date
,`classgroup` varchar(50)
,`ca_weight_point` int(10) unsigned
,`exam_weight_point` int(10) unsigned
,`academic_term` varchar(50)
,`academic_year_id` int(11) unsigned
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
-- Structure for view `examsdetails_reportviews`
--
DROP TABLE IF EXISTS `examsdetails_reportviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `examsdetails_reportviews` AS select `exam_details`.`exam_detail_id` AS `exam_detail_id`,`exams`.`exam_id` AS `exam_id`,`subject_classlevels`.`subject_classlevel_id` AS `subject_classlevel_id`,`subject_classlevels`.`subject_id` AS `subject_id`,`subject_classlevels`.`classlevel_id` AS `classlevel_id`,`classrooms`.`class_id` AS `class_id`,`students`.`student_id` AS `student_id`,`subjects`.`subject_name` AS `subject_name`,`classrooms`.`class_name` AS `class_name`,concat(ucase(`students`.`first_name`),' ',lcase(`students`.`surname`),' ',lcase(`students`.`other_name`)) AS `student_fullname`,`exam_details`.`ca` AS `ca`,`exam_details`.`exam` AS `exam`,`classgroups`.`ca_weight_point` AS `ca_weight_point`,`classgroups`.`exam_weight_point` AS `exam_weight_point`,`academic_terms`.`academic_term_id` AS `academic_term_id`,`academic_terms`.`academic_term` AS `academic_term`,`exams`.`exammarked_status_id` AS `exammarked_status_id`,`academic_terms`.`academic_year_id` AS `academic_year_id`,`academic_years`.`academic_year` AS `academic_year`,`classlevels`.`classlevel` AS `classlevel`,`classlevels`.`classgroup_id` AS `classgroup_id` from ((((((((((`exams` join `exam_details` on((`exams`.`exam_id` = `exam_details`.`exam_id`))) join `subject_classlevels` on((`exams`.`subject_classlevel_id` = `subject_classlevels`.`subject_classlevel_id`))) join `subjects` on((`subject_classlevels`.`subject_id` = `subjects`.`subject_id`))) join `students` on((`exam_details`.`student_id` = `students`.`student_id`))) join `academic_terms` on((`subject_classlevels`.`academic_term_id` = `academic_terms`.`academic_term_id`))) join `academic_years` on((`academic_years`.`academic_year_id` = `academic_terms`.`academic_year_id`))) join `classlevels` on((`subject_classlevels`.`classlevel_id` = `classlevels`.`classlevel_id`))) join `students_classes` on((`students`.`student_id` = `students_classes`.`student_id`))) join `classrooms` on((`students_classes`.`class_id` = `classrooms`.`class_id`))) join `classgroups` on((`classgroups`.`classgroup_id` = `classlevels`.`classgroup_id`)));

-- --------------------------------------------------------

--
-- Structure for view `exam_subjectviews`
--
DROP TABLE IF EXISTS `exam_subjectviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `exam_subjectviews` AS select `a`.`exam_id` AS `exam_id`,`a`.`class_id` AS `class_id`,`f`.`class_name` AS `class_name`,`c`.`subject_name` AS `subject_name`,`b`.`subject_id` AS `subject_id`,`a`.`subject_classlevel_id` AS `subject_classlevel_id`,`h`.`ca_weight_point` AS `ca_weight_point`,`h`.`exam_weight_point` AS `exam_weight_point`,`a`.`exammarked_status_id` AS `exammarked_status_id`,`f`.`classlevel_id` AS `classlevel_id`,`g`.`classlevel` AS `classlevel`,`b`.`academic_term_id` AS `academic_term_id`,`d`.`academic_term` AS `academic_term`,`d`.`academic_year_id` AS `academic_year_id`,`e`.`academic_year` AS `academic_year` from ((((((`exams` `a` left join (`classlevels` `g` join `classrooms` `f` on((`f`.`classlevel_id` = `g`.`classlevel_id`))) on((`a`.`class_id` = `f`.`class_id`))) join `subject_classlevels` `b` on((`a`.`subject_classlevel_id` = `b`.`subject_classlevel_id`))) join `subjects` `c` on((`b`.`subject_id` = `c`.`subject_id`))) join `academic_terms` `d` on((`b`.`academic_term_id` = `d`.`academic_term_id`))) join `academic_years` `e` on((`d`.`academic_year_id` = `e`.`academic_year_id`))) join `classgroups` `h` on((`g`.`classgroup_id` = `h`.`classgroup_id`)));

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

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `students_subjectsviews` AS select `a`.`student_id` AS `student_id`,`a`.`class_id` AS `class_id`,`a`.`subject_classlevel_id` AS `subject_classlevel_id`,concat(ucase(`b`.`first_name`),', ',`b`.`surname`,' ',`b`.`other_name`) AS `student_name`,`b`.`student_no` AS `student_no`,`c`.`class_name` AS `class_name`,`e`.`subject_id` AS `subject_id`,`f`.`subject_name` AS `subject_name`,`c`.`classlevel_id` AS `classlevel_id`,`d`.`classlevel` AS `classlevel`,`e`.`academic_term_id` AS `academic_term_id`,`h`.`academic_term` AS `academic_term` from ((((((`subject_students_registers` `a` join `students` `b` on((`a`.`student_id` = `b`.`student_id`))) join `classrooms` `c` on((`a`.`class_id` = `c`.`class_id`))) join `classlevels` `d` on((`c`.`classlevel_id` = `d`.`classlevel_id`))) join `subject_classlevels` `e` on((`e`.`subject_classlevel_id` = `a`.`subject_classlevel_id`))) join `subjects` `f` on((`f`.`subject_id` = `e`.`subject_id`))) join `academic_terms` `h` on((`h`.`academic_term_id` = `e`.`academic_term_id`)));

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
-- Structure for view `weeklyreport_studentdetailsviews`
--
DROP TABLE IF EXISTS `weeklyreport_studentdetailsviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `weeklyreport_studentdetailsviews` AS select `f`.`weekly_report_id` AS `weekly_report_id`,`f`.`subject_classlevel_id` AS `subject_classlevel_id`,`f`.`weekly_detail_setup_id` AS `weekly_detail_setup_id`,`f`.`marked_status` AS `marked_status`,`f`.`notification_status` AS `notification_status`,`g`.`weekly_report_detail_id` AS `weekly_report_detail_id`,`g`.`student_id` AS `student_id`,`j`.`student_no` AS `student_no`,concat(`j`.`first_name`,' ',`j`.`surname`) AS `student_name`,`j`.`gender` AS `gender`,`g`.`weekly_ca` AS `weekly_ca`,`h`.`weekly_weight_point` AS `weekly_weight_point`,`h`.`weekly_report_no` AS `weekly_report_no`,`h`.`weekly_weight_percent` AS `weekly_weight_percent`,`h`.`report_description` AS `report_description`,`h`.`submission_date` AS `submission_date`,`i`.`weekly_report_setup_id` AS `weekly_report_setup_id`,`i`.`weekly_report` AS `weekly_report`,`m`.`ca_weight_point` AS `ca_weight_point`,`m`.`exam_weight_point` AS `exam_weight_point`,`j`.`sponsor_id` AS `sponsor_id`,`j`.`image_url` AS `image_url`,`k`.`sponsor_no` AS `sponsor_no`,`k`.`mobile_number1` AS `mobile_number1`,`k`.`email` AS `email`,concat(`k`.`first_name`,' ',`k`.`other_name`) AS `sponsor_name`,`b`.`subject_id` AS `subject_id`,`b`.`subject_name` AS `subject_name`,`a`.`class_id` AS `class_id`,`c`.`class_name` AS `class_name`,`c`.`classlevel_id` AS `classlevel_id`,`d`.`classlevel` AS `classlevel`,`d`.`classgroup_id` AS `classgroup_id`,`a`.`academic_term_id` AS `academic_term_id`,`e`.`academic_term` AS `academic_term` from (((((((((((`subject_classlevels` `a` join `subjects` `b` on((`a`.`subject_id` = `b`.`subject_id`))) join `classrooms` `c` on((`a`.`class_id` = `c`.`class_id`))) join `classlevels` `d` on((`a`.`classlevel_id` = `d`.`classlevel_id`))) join `academic_terms` `e` on((`a`.`academic_term_id` = `e`.`academic_term_id`))) join `weekly_reports` `f` on((`a`.`subject_classlevel_id` = `f`.`subject_classlevel_id`))) join `weekly_report_details` `g` on((`f`.`weekly_report_id` = `g`.`weekly_report_id`))) join `weekly_detail_setups` `h` on((`f`.`weekly_detail_setup_id` = `h`.`weekly_detail_setup_id`))) join `weekly_report_setups` `i` on((`h`.`weekly_report_setup_id` = `i`.`weekly_report_setup_id`))) join `students` `j` on((`g`.`student_id` = `j`.`student_id`))) join `sponsors` `k` on((`j`.`sponsor_id` = `k`.`sponsor_id`))) join `classgroups` `m` on((`d`.`classgroup_id` = `m`.`classgroup_id`)));

-- --------------------------------------------------------

--
-- Structure for view `weekly_setupviews`
--
DROP TABLE IF EXISTS `weekly_setupviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `weekly_setupviews` AS select `a`.`weekly_report_setup_id` AS `weekly_report_setup_id`,`a`.`weekly_report` AS `weekly_report`,`b`.`weekly_weight_point` AS `weekly_weight_point`,`b`.`weekly_weight_percent` AS `weekly_weight_percent`,`a`.`classgroup_id` AS `classgroup_id`,`a`.`academic_term_id` AS `academic_term_id`,`b`.`weekly_detail_setup_id` AS `weekly_detail_setup_id`,`b`.`weekly_report_no` AS `weekly_report_no`,`b`.`report_description` AS `report_description`,`b`.`submission_date` AS `submission_date`,`c`.`classgroup` AS `classgroup`,`c`.`ca_weight_point` AS `ca_weight_point`,`c`.`exam_weight_point` AS `exam_weight_point`,`d`.`academic_term` AS `academic_term`,`d`.`academic_year_id` AS `academic_year_id` from (((`weekly_report_setups` `a` join `weekly_detail_setups` `b` on((`a`.`weekly_report_setup_id` = `b`.`weekly_report_setup_id`))) join `classgroups` `c` on((`a`.`classgroup_id` = `c`.`classgroup_id`))) join `academic_terms` `d` on((`a`.`academic_term_id` = `d`.`academic_term_id`)));

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
-- Indexes for table `attends`
--
ALTER TABLE `attends`
 ADD PRIMARY KEY (`attend_id`), ADD KEY `class_id` (`class_id`,`employee_id`,`academic_term_id`);

--
-- Indexes for table `attend_details`
--
ALTER TABLE `attend_details`
 ADD KEY `student_id` (`student_id`,`attend_id`);

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
-- Indexes for table `employees`
--
ALTER TABLE `employees`
 ADD PRIMARY KEY (`employee_id`), ADD KEY `salutation_id` (`salutation_id`), ADD KEY `employee_type_id` (`employee_type_id`), ADD KEY `state_id` (`state_id`), ADD KEY `local_govt_id` (`local_govt_id`);

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
-- Indexes for table `exams`
--
ALTER TABLE `exams`
 ADD PRIMARY KEY (`exam_id`), ADD KEY `class_id` (`class_id`,`subject_classlevel_id`,`exammarked_status_id`);

--
-- Indexes for table `exam_details`
--
ALTER TABLE `exam_details`
 ADD PRIMARY KEY (`exam_detail_id`), ADD KEY `exam_id` (`exam_id`,`student_id`);

--
-- Indexes for table `grades`
--
ALTER TABLE `grades`
 ADD PRIMARY KEY (`grades_id`), ADD KEY `classgroup_id` (`classgroup_id`);

--
-- Indexes for table `items`
--
ALTER TABLE `items`
 ADD PRIMARY KEY (`item_id`), ADD KEY `item_type_id` (`item_type_id`);

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
-- Indexes for table `messages`
--
ALTER TABLE `messages`
 ADD PRIMARY KEY (`message_id`);

--
-- Indexes for table `message_recipients`
--
ALTER TABLE `message_recipients`
 ADD PRIMARY KEY (`message_recipient_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
 ADD PRIMARY KEY (`order_id`), ADD KEY `student_id` (`student_id`,`sponsor_id`,`academic_term_id`,`process_item_id`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
 ADD PRIMARY KEY (`order_item_id`), ADD KEY `item_id` (`item_id`,`order_id`);

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
-- Indexes for table `skills`
--
ALTER TABLE `skills`
 ADD PRIMARY KEY (`skill_id`);

--
-- Indexes for table `skill_assessments`
--
ALTER TABLE `skill_assessments`
 ADD PRIMARY KEY (`skill_assessment_id`), ADD KEY `skill_id` (`skill_id`,`assessment_id`);

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
-- Indexes for table `students`
--
ALTER TABLE `students`
 ADD PRIMARY KEY (`student_id`), ADD KEY `class_id` (`class_id`,`academic_term_id`,`local_govt_id`,`student_status_id`,`state_id`,`country_id`,`relationtype_id`,`sponsor_id`);

--
-- Indexes for table `students_classes`
--
ALTER TABLE `students_classes`
 ADD PRIMARY KEY (`student_class_id`), ADD KEY `student_id` (`student_id`,`class_id`,`academic_year_id`);

--
-- Indexes for table `student_status`
--
ALTER TABLE `student_status`
 ADD PRIMARY KEY (`student_status_id`);

--
-- Indexes for table `subjects`
--
ALTER TABLE `subjects`
 ADD PRIMARY KEY (`subject_id`), ADD KEY `subject_group_id` (`subject_group_id`);

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
-- Indexes for table `users`
--
ALTER TABLE `users`
 ADD PRIMARY KEY (`user_id`), ADD KEY `user_role_id` (`user_role_id`);

--
-- Indexes for table `user_roles`
--
ALTER TABLE `user_roles`
 ADD PRIMARY KEY (`user_role_id`);

--
-- Indexes for table `weekly_detail_setups`
--
ALTER TABLE `weekly_detail_setups`
 ADD PRIMARY KEY (`weekly_detail_setup_id`), ADD KEY `weekly_report_setup_id` (`weekly_report_setup_id`);

--
-- Indexes for table `weekly_reports`
--
ALTER TABLE `weekly_reports`
 ADD PRIMARY KEY (`weekly_report_id`), ADD KEY `subject_classlevel_id` (`subject_classlevel_id`,`weekly_detail_setup_id`);

--
-- Indexes for table `weekly_report_details`
--
ALTER TABLE `weekly_report_details`
 ADD PRIMARY KEY (`weekly_report_detail_id`), ADD KEY `exam_id` (`weekly_report_id`,`student_id`);

--
-- Indexes for table `weekly_report_setups`
--
ALTER TABLE `weekly_report_setups`
 ADD PRIMARY KEY (`weekly_report_setup_id`), ADD KEY `classgroup_id` (`classgroup_id`,`academic_term_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `academic_terms`
--
ALTER TABLE `academic_terms`
MODIFY `academic_term_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `academic_years`
--
ALTER TABLE `academic_years`
MODIFY `academic_year_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `acos`
--
ALTER TABLE `acos`
MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=171;
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
MODIFY `class_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `countries`
--
ALTER TABLE `countries`
MODIFY `country_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=234;
--
-- AUTO_INCREMENT for table `employees`
--
ALTER TABLE `employees`
MODIFY `employee_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=12;
--
-- AUTO_INCREMENT for table `employee_qualifications`
--
ALTER TABLE `employee_qualifications`
MODIFY `employee_qualification_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `employee_types`
--
ALTER TABLE `employee_types`
MODIFY `employee_type_id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `exams`
--
ALTER TABLE `exams`
MODIFY `exam_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=31;
--
-- AUTO_INCREMENT for table `exam_details`
--
ALTER TABLE `exam_details`
MODIFY `exam_detail_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=209;
--
-- AUTO_INCREMENT for table `grades`
--
ALTER TABLE `grades`
MODIFY `grades_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=14;
--
-- AUTO_INCREMENT for table `items`
--
ALTER TABLE `items`
MODIFY `item_id` int(11) NOT NULL AUTO_INCREMENT;
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
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
MODIFY `message_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `message_recipients`
--
ALTER TABLE `message_recipients`
MODIFY `message_recipient_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
MODIFY `order_item_id` int(11) NOT NULL AUTO_INCREMENT;
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
MODIFY `remark_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
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
-- AUTO_INCREMENT for table `skills`
--
ALTER TABLE `skills`
MODIFY `skill_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=18;
--
-- AUTO_INCREMENT for table `skill_assessments`
--
ALTER TABLE `skill_assessments`
MODIFY `skill_assessment_id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `sponsors`
--
ALTER TABLE `sponsors`
MODIFY `sponsor_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
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
-- AUTO_INCREMENT for table `students`
--
ALTER TABLE `students`
MODIFY `student_id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=32;
--
-- AUTO_INCREMENT for table `students_classes`
--
ALTER TABLE `students_classes`
MODIFY `student_class_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=32;
--
-- AUTO_INCREMENT for table `student_status`
--
ALTER TABLE `student_status`
MODIFY `student_status_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=6;
--
-- AUTO_INCREMENT for table `subjects`
--
ALTER TABLE `subjects`
MODIFY `subject_id` int(3) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=47;
--
-- AUTO_INCREMENT for table `subject_classlevels`
--
ALTER TABLE `subject_classlevels`
MODIFY `subject_classlevel_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=61;
--
-- AUTO_INCREMENT for table `subject_groups`
--
ALTER TABLE `subject_groups`
MODIFY `subject_group_id` int(3) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `teachers_classes`
--
ALTER TABLE `teachers_classes`
MODIFY `teacher_class_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `teachers_subjects`
--
ALTER TABLE `teachers_subjects`
MODIFY `teachers_subjects_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=61;
--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
MODIFY `user_id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=19;
--
-- AUTO_INCREMENT for table `user_roles`
--
ALTER TABLE `user_roles`
MODIFY `user_role_id` int(3) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `weekly_detail_setups`
--
ALTER TABLE `weekly_detail_setups`
MODIFY `weekly_detail_setup_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=15;
--
-- AUTO_INCREMENT for table `weekly_reports`
--
ALTER TABLE `weekly_reports`
MODIFY `weekly_report_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=206;
--
-- AUTO_INCREMENT for table `weekly_report_details`
--
ALTER TABLE `weekly_report_details`
MODIFY `weekly_report_detail_id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=1441;
--
-- AUTO_INCREMENT for table `weekly_report_setups`
--
ALTER TABLE `weekly_report_setups`
MODIFY `weekly_report_setup_id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
