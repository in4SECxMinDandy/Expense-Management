import sqlite3
import os

class SpendingAI:
    def __init__(self, db_path):
        self.db_path = db_path

    def get_connection(self):
        return sqlite3.connect(self.db_path)

    def analyze_spending(self):
        conn = self.get_connection()
        cursor = conn.cursor()
        
        # Example query: Total expense by category
        query = '''
            SELECT c.name, SUM(t.amount) 
            FROM transactions t
            JOIN categories c ON t.category_id = c.id
            WHERE t.type = 'expense'
            GROUP BY c.name
        '''
        cursor.execute(query)
        results = cursor.fetchall()
        
        analysis = "Analysis Results:\n"
        for name, total in results:
            analysis += f"- {name}: {total}\n"
        
        conn.close()
        return analysis

    def save_insight(self, period, insight, prediction=None):
        conn = self.get_connection()
        cursor = conn.cursor()
        
        query = '''
            INSERT INTO ai_insights (period, insight, prediction)
            VALUES (?, ?, ?)
        '''
        cursor.execute(query, (period, insight, prediction))
        conn.commit()
        conn.close()

if __name__ == "__main__":
    # Path to the database file (adjust as needed for development)
    db_file = "expense_manager.db" 
    
    ai = SpendingAI(db_file)
    # This is a placeholder for actual AI logic
    print("AI Analysis started...")
    # ai.analyze_spending()
