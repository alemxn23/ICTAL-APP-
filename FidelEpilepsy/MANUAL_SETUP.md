# Manual Setup Guide (Updated)

You successfully created the project! Now let's add the Watch App and the code.

## 1. Add Watch App Target
Your project currently only has the iOS App. Let's add the Watch App:
1.  In Xcode, go to **File > New > Target...**
2.  Select the **watchOS** tab.
3.  Choose **App** and click **Next**.
4.  **Product Name**: `EpilepsiaWatch` (or similar).
5.  **Watch App for Existing iOS App**: Ensure `Epilepsia APP` is selected.
6.  Click **Finish**.

## 2. Import the Code
Now locate the `FidelEpilepsy` folder in Finder (where you found this file). You need to drag the following folders into your Xcode project sidebar:

### A. Shared Code (Models)
1.  Drag the **`Shared`** folder from Finder into your Xcode Project Navigator (top level).
2.  In the dialog:
    *   Check **Copy items if needed**.
    *   Select **Create groups**.
    *   **Important**: In "Add to targets", check **BOTH** `Epilepsia APP` and `EpilepsiaWatch`.

### B. Watch App Code
1.  Open the `WatchApp` folder in Finder.
2.  Drag its contents (Managers, Views, etc.) into the `EpilepsiaWatch` group in Xcode.
3.  **Target**: Check **ONLY** `EpilepsiaWatch`.

### C. iOS App Code
1.  Open the `iOS` folder in Finder.
2.  Drag its contents (Managers, Views, etc.) into the `Epilepsia APP` group in Xcode.
3.  **Target**: Check **ONLY** `Epilepsia APP`.

## 3. Configuration & Permissions
1.  **Info.plist**: Add the HealthKit privacy keys as described before to both targets.
2.  **Capabilities**: Add **HealthKit** capability to the Watch App target.

## 4. Build & Run
Select the specific Watch Simulator scheme (e.g., `EpilepsiaWatch`) or the iOS scheme and run!
