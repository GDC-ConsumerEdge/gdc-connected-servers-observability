# Gemini Added Memories for MQL2PromQL Agent

---

### General Plan for MQL to PromQL Alert Conversion

This plan outlines a systematic approach for converting a single MQL-based alert to its PromQL equivalent, including creation, deployment, validation, and documentation.

---

#### **Phase 1: Initialization and Planning**

1.  **Analyze the Source MQL Alert:**
    *   Identify the target MQL alert file (e.g., `.../alert-name.yaml`).
    *   Thoroughly review the MQL query to understand its core logic:
        *   What is the primary goal of the alert?
        *   What metrics are being used?
        *   What filters, joins, and conditions are applied?
        *   What is the trigger condition (e.g., `count`, `duration`)?

2.  **Create Placeholder Documentation:**
    *   Create a new, empty, or placeholder markdown file in the `mql2promql/docs/alerts/...` directory (e.g., `.../alert-name-promql-doc.md`). This file will be populated with the full analysis after validation.

3.  **Update the Master Status Document:**
    *   In `mql2promql/MQL_TO_PROMQL_CONVERSION_STATUS.md`, locate the row for the target alert.
    *   Change the `Conversion Status` from "TBD" to "**WIP**".
    *   Add the paths to the (not yet created) converted alert file and the new placeholder documentation file in their respective columns.

---

#### **Phase 2: PromQL Conversion and File Creation**

1.  **Draft the PromQL Query:**
    *   Translate the MQL logic into a PromQL query, paying close attention to metric name conversion, filter syntax, and join logic (`and on()` vs. `* on()`).
    *   Reference successful conversions of similar alerts (e.g., CPU usage vs. Memory usage) to ensure consistency and correctness.

2.  **Create the PromQL Alert File:**
    *   Create a new YAML file in the `mql2promql/alerts-promql/...` directory (e.g., `.../alert-name-promql.yaml`).
    *   Structure the YAML file correctly, ensuring proper indentation. **Crucially, the `displayName` for the condition must be a sibling to the `conditionPrometheusQueryLanguage` block, not nested within it.**
    *   Embed the new PromQL query into the `query` field.

3.  **Create Empty Testing/Validation Files:**
    *   Create empty markdown files in the `mql2promql/testing/alerts/...` directory for the validation report and analysis (e.g., `...-validation.md` and `...-analysis.md`).

---

#### **Phase 3: Iterative Deployment and Debugging**

1.  **Deploy the Converted Alert:**
    *   Run the `./create-alerts-promql.sh` script from the `mql2promql/alerts-promql` directory to deploy the new alert policy.

2.  **Validate and Debug:**
    *   Carefully review the deployment script's output for any errors.
    *   If an error occurs, analyze the message to identify the root cause. Common issues include:
        *   **YAML Formatting Errors:** Incorrect indentation, especially for the `displayName` field.
        *   **Invalid Metric Names:** The metric does not exist or is not queryable for the specified resource.
        *   **Incorrect Join Logic:** Using `*` when `and` is needed, or having mismatched labels.
    *   Use the Google Cloud Monitoring "Metrics Explorer" to test and debug parts of the PromQL query independently.

3.  **Correct and Redeploy:**
    *   Apply the necessary corrections to the PromQL alert's YAML file.
    *   Repeat steps 1 and 2 until the deployment is successful.

---

#### **Phase 4: Final Documentation and Status Update**

1.  **Incorporate Test Agent Feedback:**
    *   Once the alert is deployed successfully, a Test Agent will provide a detailed validation and analysis report (e.g., in the `...-validation.md` file).

2.  **Finalize the Conversion Document:**
    *   Update the placeholder documentation file (`...-promql-doc.md`) with the full content from the Test Agent's validation report. This should include the final MQL and PromQL queries, the reasoning for the conversion, and a summary of the validation process.

3.  **Update the Master Status Document:**
    *   In `mql2promql/MQL_TO_PROMQL_CONVERSION_STATUS.md`, change the `Conversion Status` for the alert from "WIP" to "**To be verified**" to indicate that the conversion is complete and ready for final review.

---

#### Other Instructions

- When converting MQL to PromQL for alert YAML files, ensure the 'displayName' field for a condition is a sibling to 'conditionPrometheusQueryLanguage', not nested under it. Pay close attention to YAML indentation.
- When creating conversion documentation, avoid duplicating titles within the same document. Ensure that the main title and any section titles are unique and clearly differentiate content.