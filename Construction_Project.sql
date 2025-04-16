

/** 1. List all ongoing projects with their client names and budgets.**/

Select ProjectID, ProjectName, ClientName, Budget 
From Projects
Where status = 'ongoing'
Order By StartDate;

/** 2. Which departments have employees with an average salary greater than $60,000?**/

Select Department, AVG(Salary) as DeptAvgSalary
From Employee
Group By Department
Having AVG(Salary) > 60000;

/** Explanation: 
GROUP BY Department lets us compute salary stats for each department.

HAVING filters groups where the average salary is greater than $60,000. **/


/** 3. Find the total hours worked per project.**/

Select t.ProjectID,p.ProjectName, t.TaskName, SUM(t.HoursWorked) as TotalHoursWorked
From Task t
LEFT JOIN Projects p
ON t.ProjectID = p.ProjectID
Group By t.ProjectID, t.TaskName, p.ProjectName
Order By TotalHoursWorked DESC;

/** Explanation: SUM Aggregates total HoursWorked for each ProjectID from the Tasks table
The Left Join pulls all the Rows from the Tasks and matching rows from the Project table **/


/**4. List each material used for Project ID 1, showing total cost per material**/

Select ProjectID, MaterialID, MaterialName, (Quantity * Unitcost) as TotalCost, Supplier
From Materials
Where ProjectID = 1;

/** Explanation : Calculate TotalCost as Quantity × UnitCost and filter only rows for Project ID 1.**/

/**5. Which employees were hired before January 1, 2021?**/
Select *
From Employee
Where HireDate < '01-01-2021';

/**6. Find employees whose salary is higher than the average salary of their department. **/

Select e.EmployeeID, e.FirstName, e.LastName, e.Department, e.Salary
From Employee e
Where Salary >  (Select AVG(Salary)
From Employee
Where e.Department = Department)

/** Explanation: 
The subquery calculates the average salary for the same department as each employee in the outer query. 
It runs once per employee, not once for the whole table.**/


/** 7. List projects whose total material cost exceeds $100,000**/
Select ProjectID, SUM(Quantity * UnitCost) as MaterialCost
From Materials
Group By ProjectID
HAVING SUM(Quantity * UnitCost) > 100000

/** Explanation : 
The Sum aggregates the Material Costs and then Group by groups materials by project .
HAVING filters only projects where the sum is over $100,000. **/


/** 8. Display employees who have worked on more than 1 task.**/

Select e.FirstName, e.LastName, Count(t.AssignedTo) as TotalTasks
From Employee e
Left Join Task t
On e.EmployeeID = t.AssignedTo
Group By e.FirstName, e.LastName
Having Count(t.AssignedTo) > 1

/** The Count aggregate counts tasks assigned to each employee.
HAVING filters only those with more than 1 task.**/

/** 9. Which supplier has supplied the highest total value of materials (total cost = quantity × unit cost)**/
With RankedSupply as 

                     (Select Supplier, SUM(Quantity * UnitCost) as TotalCost
					 From Materials
					 Group by Supplier),
	RankedSupplier as (Select Supplier, TotalCost, Row_Number() Over(Order by TotalCost Desc) as rn
	                   From RankedSupply)
	                   Select Supplier, TotalCost
					   From RankedSupplier
					   Where rn = 1;

/** The First CTE calculates the total value supplied per supplier.
The  Second CTE ranks suppliers by total value.
The Final query picks the top one (rn = 1).**/

/** 10. Which projects have consumed more than the average hours across all projects?**/
With ProjectHours As 
                   (Select ProjectID, SUM(HoursWorked) as TotalHours
				   From Task
				   Group By ProjectID),
        AverageHours as ( Select AVG(TotalHours) as AvgHours From ProjectHours)
Select ph.ProjectID, ph.TotalHours
From ProjectHours ph, AverageHours ah
Where ph.TotalHours > ah.AvgHours;

/**The First CTE, calculates total hours per project.
The Second CTE calculates the average of those totals.
Then the final query filters projects above that average.**/

/**11. For each employee, display their salary and the average salary of their department.**/

Select EmployeeID,FirstName, LastName, Department, Salary, AVG(Salary) Over (Partition By Department) As AvgDeptSalary
From Employee;
/**  The Window  function shows the department average.**/

/** 12. Rank employees within each department based on salary (highest to lowest).**/
Select EmployeeID, FirstName, LastName, Department, Salary, Rank() Over (Partition By Department Order by Salary DESC) as EmployeeRank
From Employee;

/** The Over (Partition By) query partitions the data by department and ranks employees by salary within each group.
RANK() handles ties.**/

/** 13. For each task, show the hours worked and the cumulative hours by that employee, ordered by start date.**/

Select AssignedTo as EmployeeID, TaskID, HoursWorked, SUM(HoursWorked) Over(Partition By AssignedTo Order by StartDate ) as TotalHours
From Task;

/**The query  tracks the task effort per employee, with a running total of hours using SUM() OVER.**/


/** 14. Show the 2 most recent tasks assigned to each employee.**/

Select *
From( 
       Select *, Row_Number() Over(Partition By AssignedTo Order By StartDate DESC) as rn
	   From Task
	   ) ranked
Where rn <= 2;

/** The query assigns row numbers to tasks per employee, based on latest StartDate.
Using where to filter the top 2 tasks per person.**/

/** 15. What percentage of the total budget has been spent on materials for each project? **/

Select p.ProjectID, p.ProjectName, p.Budget, ISNULL(SUM(m.Quantity * m.UnitCost), 0) as MaterialCost,
       ROUND((ISNULL(SUM(m.Quantity * m.UnitCost), 0) / p.Budget) *100, 2) as PercentSpent
	   From Projects p
	   Left Join Materials m ON p.ProjectID = m.ProjectID
	   Group By p.ProjectID, p.ProjectName, p.Budget;

/** Left Join joins projects with materials to calculate total material cost.
ISNULL() handles cases where a project has no materials yet.
Calculates % spent as a ratio of material cost to budget.
ROUND () rounds to the calculation to the closest whole number.**/

