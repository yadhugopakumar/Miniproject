
import { useState, useEffect } from "react";
import { Pie } from "react-chartjs-2";
import jsPDF from "jspdf";
import { supabase } from "../supabase/supabase-client";
import autoTable from "jspdf-autotable";
import { format, subMonths, addMonths, startOfMonth, endOfMonth, isFuture, getMonth, getYear, setMonth, setYear } from "date-fns";

// --- Helper Data for Select Boxes ---
const currentYear = getYear(new Date());
const MIN_YEAR = currentYear - 10;

const yearOptions = Array.from({ length: currentYear - MIN_YEAR + 1 }, (_, i) => ({
    value: MIN_YEAR + i,
    label: MIN_YEAR + i
}));

const monthOptions = [
    { value: 0, label: "January" },
    { value: 1, label: "February" },
    { value: 2, label: "March" },
    { value: 3, label: "April" },
    { value: 4, label: "May" },
    { value: 5, label: "June" },
    { value: 6, label: "July" },
    { value: 7, label: "August" },
    { value: 8, label: "September" },
    { value: 9, label: "October" },
    { value: 10, label: "November" },
    { value: 11, label: "December" },
];
// ------------------------------------


export default function MedicineStats({ childId, username }) {
    const [showDetails, setShowDetails] = useState(false);
    const [aggregatedCounts, setAggregatedCounts] = useState({});
    const [pieData, setPieData] = useState({});
    const [loading, setLoading] = useState(true);

    // hasHistory: True if there is data for the CURRENTLY selected month
    const [hasHistory, setHasHistory] = useState(false);

    // NEW: hasAnyHistory: True if there is EVER any data for this child
    const [hasAnyHistory, setHasAnyHistory] = useState(true);
    // Set to true initially to prevent flash until the check runs
    const [initialCheckLoading, setInitialCheckLoading] = useState(true); // Tracks initial existence check

    const [selectedMonth, setSelectedMonth] = useState(
        startOfMonth(new Date())
    );

    const monthLabel = format(selectedMonth, "yyyy - MMMM");
    const isCurrentOrFutureMonth = isFuture(addMonths(selectedMonth, 1));

    const currentSelectedYear = getYear(selectedMonth);
    const currentSelectedMonth = getMonth(selectedMonth);

    // --- INITIAL HISTORY CHECK EFFECT (Runs once on mount) ---

    useEffect(() => {
        async function checkOverallHistory() {
            setInitialCheckLoading(true);
            console.log("Checking history for childId:", childId);

            const { count, error } = await supabase
                .from("history_entry")
                .select("id", { head: true, count: 'exact' })
                .eq("child_id", childId)
                .limit(1);

            if (error) {
                setHasAnyHistory(false);
            } else {
                setHasAnyHistory((count || 0) > 0);
            }
            setInitialCheckLoading(false);
        }
        checkOverallHistory();
    }, [childId]);
    // --- END INITIAL HISTORY CHECK EFFECT ---


    function handleYearChange(e) {
        const newYear = Number(e.target.value);
        let newDate = setYear(selectedMonth, newYear);

        if (isFuture(newDate) && newDate > startOfMonth(new Date())) {
            newDate = startOfMonth(new Date());
        }

        setSelectedMonth(newDate);
    }

    function handleMonthChange(e) {
        const newMonth = Number(e.target.value);
        let newDate = setMonth(selectedMonth, newMonth);

        if (isFuture(newDate) && newDate > startOfMonth(new Date())) {
            newDate = startOfMonth(new Date());
        }

        setSelectedMonth(newDate);
    }


    function goPrevMonth() {
        setSelectedMonth((prev) => subMonths(prev, 1));
    }

    function goNextMonth() {
        if (!isCurrentOrFutureMonth) {
            setSelectedMonth((prev) => addMonths(prev, 1));
        }
    }

    useEffect(() => {
        // Prevent fetching if the initial check hasn't run or shows no history
        if (initialCheckLoading || !hasAnyHistory) {
            if (!initialCheckLoading) setLoading(false);
            return;
        }

        async function fetchMedicineStats() {
            setLoading(true);

            const monthStart = format(startOfMonth(selectedMonth), "yyyy-MM-dd");
            const monthEnd = format(endOfMonth(selectedMonth), "yyyy-MM-dd");

            const { data: history, error } = await supabase
                .from("history_entry")
                .select("*")
                .eq("child_id", childId)
                .gte("date", monthStart)
                .lte("date", monthEnd);

            if (error) {
                console.error("Error fetching medicine stats:", error);
                setLoading(false);
                setHasHistory(false);
                setAggregatedCounts({});
                setPieData({});
                return;
            }

            if (!history || history.length === 0) {
                setHasHistory(false);
                setLoading(false);
                setAggregatedCounts({});
                setPieData({});
                return;
            }

            setHasHistory(true);

            const counts = {};
            history.forEach((entry) => {
                if (!counts[entry.medicine_name]) {
                    counts[entry.medicine_name] = {
                        taken: 0,
                        missed: 0,
                        late: 0,
                        details: [],
                    };
                }

                counts[entry.medicine_name].details.push({
                    date: entry.date,
                    time: entry.time,
                    status: entry.status,
                });

                if (entry.status === "taken") counts[entry.medicine_name].taken++;
                else if (entry.status === "missed") counts[entry.medicine_name].missed++;
                else if (entry.status === "takenLate") counts[entry.medicine_name].late++;
            });

            setAggregatedCounts(counts);

            const totalTaken = Object.values(counts).reduce((a, c) => a + c.taken, 0);
            const totalMissed = Object.values(counts).reduce((a, c) => a + c.missed, 0);
            const totalLate = Object.values(counts).reduce((a, c) => a + c.late, 0);

            setPieData({
                labels: ["Taken", "Missed", "Late"],
                datasets: [
                    {
                        data: [totalTaken, totalMissed, totalLate],
                        backgroundColor: ["#22c55e", "#ef4444", "#facc15"],
                    },
                ],
            });

            setLoading(false);
        }

        fetchMedicineStats();
    }, [childId, selectedMonth, initialCheckLoading, hasAnyHistory]); // Rerun if these base flags change


    // --- CONDITIONAL RENDERING LOGIC ---

    if (initialCheckLoading) {
        return (
            <section className="bg-white shadow rounded p-6">
                <div className="text-center py-10">
                    <div className="animate-spin inline-block h-8 w-8 border-4 border-t-4 border-blue-500 rounded-full"></div>
                    <p className="mt-2 text-blue-600">Checking initial history...</p>
                </div>
            </section>
        );
    }

    if (!hasAnyHistory) {
        return (
            <section className="bg-white shadow rounded p-6">
                <h3 className="text-xl font-semibold mb-4">Medicine Stats</h3>
                <div className="text-center py-6 text-gray-500">
                    No medicine intake history found for this child yet.
                </div>
            </section>
        );
    }
    // --- END CONDITIONAL RENDERING LOGIC ---


    return (
        <section className="bg-white shadow rounded p-6">
            <h3 className="text-xl font-semibold mb-4">Medicine Stats</h3>

            {/* Month Selector: RENDERED ONLY IF hasAnyHistory IS TRUE */}
            <div className="mb-4 flex flex-col sm:flex-row justify-end items-center space-y-2 sm:space-y-0 sm:space-x-4">

                {/* Year Selector */}
                <select
                    value={currentSelectedYear}
                    onChange={handleYearChange}
                    className="border border-gray-300 rounded px-3 py-1.5 text-lg font-semibold cursor-pointer focus:ring-2 focus:ring-blue-500"
                >
                    {yearOptions.map(option => (
                        <option key={option.value} value={option.value}>{option.label}</option>
                    ))}
                </select>

                {/* Month Selector */}
                <select
                    value={currentSelectedMonth}
                    onChange={handleMonthChange}
                    className="border border-gray-300 rounded px-3 py-1.5 text-lg font-semibold cursor-pointer focus:ring-2 focus:ring-blue-500"
                >
                    {monthOptions.map(option => (
                        <option
                            key={option.value}
                            value={option.value}
                            // Optionally disable future months in the current year
                            disabled={currentSelectedYear === currentYear && option.value > getMonth(new Date())}
                        >
                            {option.label}
                        </option>
                    ))}
                </select>

                {/* Left/Right Buttons (Simplified Styling) */}
                <div className="flex items-center rounded-md space-x-1">
                    <button
                        onClick={goPrevMonth}
                        className="p-2 bg-gray-800 text-white hover:bg-gray-600 rounded text-base transition-colors"
                    >
                        ◀
                    </button>
                    <button
                        onClick={goNextMonth}
                        disabled={isCurrentOrFutureMonth}
                        className={`p-2 rounded text-base transition-colors ${isCurrentOrFutureMonth
                            ? 'bg-gray-400 text-gray-700 cursor-not-allowed'
                            : 'bg-gray-800 text-white hover:bg-gray-600'}`}
                    >
                        ▶
                    </button>
                </div>
            </div>

            {/* Conditional Content */}
            {loading ? (
                <div className="text-center py-10">
                    <div className="animate-spin inline-block h-8 w-8 border-4 border-t-4 border-blue-500 rounded-full"></div>
                    <p className="mt-2 text-blue-600">Loading data for {monthLabel}...</p>
                </div>
            ) : hasHistory ? (
                <>
                    {/* summary cards */}
                    <div className="grid grid-cols-3 gap-6 text-center mb-4">
                        <div className="bg-red-50 p-4 rounded shadow">
                            <div className="text-2xl font-bold text-red-600">
                                {Object.values(aggregatedCounts).reduce((a, c) => a + c.missed, 0)}
                            </div>
                            <div className="text-gray-700 font-medium">Missed</div>
                        </div>
                        <div className="bg-green-50 p-4 rounded shadow">
                            <div className="text-2xl font-bold text-green-600">
                                {Object.values(aggregatedCounts).reduce((a, c) => a + c.taken, 0)}
                            </div>
                            <div className="text-gray-700 font-medium">Taken</div>
                        </div>
                        <div className="bg-yellow-50 p-4 rounded shadow">
                            <div className="text-2xl font-bold text-yellow-500">
                                {Object.values(aggregatedCounts).reduce((a, c) => a + c.late, 0)}
                            </div>
                            <div className="text-gray-700 font-medium">Late</div>
                        </div>
                    </div>

                    <div className="flex justify-end items-end w-full pt-2 pb-4">
                        <button
                            onClick={() => setShowDetails(true)}
                            className="
            px-6 py-2 
            bg-blue-600 hover:bg-blue-700 
            text-white 
            rounded-lg 
            font-semibold 
            shadow-md hover:shadow-lg 
            transition duration-150
            focus:outline-none focus:ring-4 focus:ring-blue-300
        "
                        >
                            View Details
                        </button>
                    </div>
                </>
            ) : (
                <div className="text-center py-6 text-gray-500">
                    No medicine intake history found for the selected month.
                </div>
            )}


            {/* Modal for Details: Renders only if showDetails is true AND we have history data */}
            {showDetails && hasHistory && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 backdrop-blur-sm overflow-auto p-4">
                    <div className="bg-white p-6 rounded shadow-lg max-w-4xl w-full space-y-6">
                        <h4 className="text-lg font-semibold text-center">
                            Medicine Intake Details for {username} ({monthLabel})
                        </h4>

                        {/* Pie Chart */}
                        <div className="flex justify-center mb-4">
                            <div style={{ width: 200, height: 200 }}>
                                <Pie
                                    data={pieData}
                                    options={{ maintainAspectRatio: false }}
                                />
                            </div>
                        </div>

                        {/* Table */}
                        <div className="overflow-auto max-h-96">
                            <table className="table-auto w-full border-collapse border mt-4">
                                <thead>
                                    <tr className="bg-gray-200">
                                        <th className="border px-2 py-1 sticky top-0 bg-gray-200">Medicine</th>
                                        <th className="border px-2 py-1 sticky top-0 bg-gray-200">Taken</th>
                                        <th className="border px-2 py-1 sticky top-0 bg-gray-200">Missed (count & times)</th>
                                        <th className="border px-2 py-1 sticky top-0 bg-gray-200">
                                            Taken Late (count & times)
                                        </th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {Object.entries(aggregatedCounts).map(([medName, data]) => {
                                        const missedDetails = data.details.filter(
                                            (d) => d.status === "missed"
                                        );
                                        const lateDetails = data.details.filter(
                                            (d) => d.status === "takenLate"
                                        );

                                        return (
                                            <tr key={medName} className="text-center">
                                                <td className="border px-2 py-1 font-medium">{medName}</td>
                                                <td className="border px-2 py-1">{data.taken}</td>
                                                <td className="border px-2 py-1 text-left">
                                                    <span className="font-bold block">{missedDetails.length} missed</span>
                                                    {missedDetails.map((d, i) => (
                                                        <div key={i} className="text-sm text-red-600">
                                                            {d.date} at {d.time}
                                                        </div>
                                                    ))}
                                                </td>
                                                <td className="border px-2 py-1 text-left">
                                                    <span className="font-bold block">{lateDetails.length} late</span>
                                                    {lateDetails.map((d, i) => (
                                                        <div key={i} className="text-sm text-yellow-700">
                                                            {d.date} at {d.time}
                                                        </div>
                                                    ))}
                                                </td>
                                            </tr>
                                        );
                                    })}
                                </tbody>
                            </table>
                        </div>

                        {/* Buttons */}
                        <div className="flex justify-between mt-4">
                            <button
                                onClick={() => setShowDetails(false)}
                                className="px-4 py-2 bg-gray-500 hover:bg-gray-600 text-white rounded shadow-md"
                            >
                                Close
                            </button>
                            <button
                                onClick={() => {
                                    const doc = new jsPDF();
                                    doc.text(
                                        `Medicine Intake Details for ${username} - ${monthLabel}`,
                                        10,
                                        10
                                    );

                                    const tableData = Object.entries(aggregatedCounts).map(
                                        ([medName, data]) => {
                                            const missedText =
                                                data.details
                                                    .filter((d) => d.status === "missed")
                                                    .map((d) => `${d.date} ${d.time}`)
                                                    .join("\n") || "-";
                                            const lateText =
                                                data.details
                                                    .filter((d) => d.status === "takenLate")
                                                    .map((d) => `${d.date} ${d.time}`)
                                                    .join("\n") || "-";

                                            return [
                                                medName,
                                                data.taken,
                                                `${data.details.filter((d) => d.status === "missed").length}\n${missedText}`,
                                                `${data.details.filter((d) => d.status === "takenLate").length}\n${lateText}`,
                                            ];
                                        }
                                    );

                                    autoTable(doc, {
                                        head: [
                                            [
                                                "Medicine",
                                                "Taken",
                                                "Missed (count + dates)",
                                                "Taken Late (count + dates)",
                                            ],
                                        ],
                                        body: tableData,
                                        startY: 20,
                                        styles: { fontSize: 8, cellPadding: 2, overflow: 'linebreak' },
                                        headStyles: { fillColor: [156, 163, 175], fontSize: 9 },
                                        columnStyles: {
                                            2: { cellWidth: 55 },
                                            3: { cellWidth: 55 }
                                        }
                                    });

                                    doc.save(`medicine_report_${format(selectedMonth, 'yyyy-MM')}.pdf`);
                                }}
                                className="px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded shadow-md"
                            >
                                Export PDF
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </section>
    );
}