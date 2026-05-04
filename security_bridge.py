
import os
import json
import sys
import time
from groq import Groq

api_key = "api_key"
client = Groq(api_key=api_key, base_url="https://api.groq.com/v1")
def perform_security_analysis():
    time.sleep(0.5)
    ast_file = "ast.json"
    
    if not os.path.exists(ast_file):
        print(f"Error: {ast_file} not found.")
        sys.exit(1)

    with open(ast_file, "r") as f:
        ast_data = f.read()

    # We ask the AI to give a simple YES/NO verdict at the end
    prompt = f"""
    Analyze this AST for security risks. 
    1. List risks.
    2. At the very end, write 'VERDICT: SAFE' or 'VERDICT: DANGEROUS'.
    Only use 'DANGEROUS' if there is an infinite loop or malicious system call.
    
    AST:
    {ast_data}
    """

    try:
        completion = client.chat.completions.create(
            messages=[{"role": "user", "content": prompt}],
            model="llama-3.3-70b-versatile",
        )
        
        report = completion.choices[0].message.content
        print("\n" + "="*40)
        print("AI AGENT REPORT")
        print("="*40)
        print(report)
        print("="*40 + "\n")

        # Better Gatekeeper Logic: Only block if the AI explicitly says DANGEROUS
        if "VERDICT: DANGEROUS" in report.upper():
            sys.exit(1) # This blocks the compiler
        else:
            sys.exit(0) # This allows execution

    except Exception as e:
        print(f"AI Analysis Failed: {e}")
        sys.exit(0) 

if __name__ == "__main__":
    perform_security_analysis()