# AI-powered Drone Delivery Management Platform

## 📌 Introduction
This project designs a database schema for a drone-based delivery system.  
The goal is to manage the entire workflow: from customer orders, package handling, drone assignment, tracking, delivery confirmation, to auditing employee actions.

## 🏗️ Document Structure
The LaTeX report is organized into 5 chapters:
- **Chapter 1: Introduction** – Background, objectives, scope.
- **Chapter 2: System Analysis** – Business requirements, use cases, conceptual model.
- **Chapter 3: Database Design** – ERD, logical design, physical design.
- **Chapter 4: Testing and Evaluation** – Test cases, evaluation criteria, results.
- **Chapter 5: Conclusion** – Summary and proposed improvements.

## 🔑 Key Entities
- **Customer**: Stores customer information.
- **DeliveryOrder**: Central entity representing each order.
- **Package**: Details of individual packages.
- **Drone**: Delivery drones with status and assignments.
- **LandingStation**: Drone stations for departure and landing.
- **DeliveryOrderStation**: Junction table for many-to-many relation between orders and stations.
- **Tracking**: Logs location/time updates during delivery.
- **DeliveryWorkflow**: Captures step-by-step process of fulfilling an order.
- **Confirmation**: Records customer confirmation of delivery.
- **User**: System employees with roles and credentials.
- **AuditLog**: Records user actions for accountability.

## 🧪 Testing and Evaluation
- **Functional Testing**: Verify entity relationships and constraints.  
- **Integrity Testing**: Ensure foreign keys prevent invalid data.  
- **Performance Testing**: Measure query execution time for Tracking and Workflow.  
- **Security Testing**: Confirm AuditLog records all user actions.  

**Sample Test Cases:**
- Insert a new Customer and link DeliveryOrder correctly.  
- Assign a Drone to an Order and check Tracking updates.  
- Simulate drone failure and verify reassignment.  
- Lost package scenario: use Tracking + DeliveryOrderStation to trace last known location.  

**Evaluation Results:**
- Schema maintains referential integrity.  
- Supports error handling (drone replacement, lost package).  
- Performance stable under simulated high load.  
- AuditLog ensures transparency and accountability.  

## 🚀 Conclusion and Future Work
**Conclusion:**  
The schema successfully models the drone delivery workflow, ensuring consistency, reliability, scalability, and transparency.  

**Future Work:**  
- Integrate IoT telemetry from drones into Tracking.  
- Implement role-based access control and encryption.  
- Extend schema for predictive analytics (delivery times, drone maintenance).  
- Add customer feedback and service quality monitoring.  
- Automate alerts for lost packages or drone failures.  


