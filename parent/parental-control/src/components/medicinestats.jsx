import { useState, useEffect } from "react";
import { Pie } from "react-chartjs-2";
import jsPDF from "jspdf";
import { supabase } from "../supabase/supabase-client";
import autoTable from "jspdf-autotable";


export default function MedicineStats({ childId, username }) {
    const [showDetails, setShowDetails] = useState(false);
    const [aggregatedCounts, setAggregatedCounts] = useState({});
    const [pieData, setPieData] = useState({});
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function fetchMedicineStats() {
            setLoading(true);
            const { data: history, error } = await supabase
                .from("history_entry")
                .select("*")
                .eq("child_id", childId);



            if (error) {
                console.error(error);
                setLoading(false);
                return;
            }


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

            // Prepare pie chart
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
    }, [childId]);

    if (loading) return <div>Loading medicine stats...</div>;

    return (
        <section className="bg-white shadow rounded p-6">
            <h3 className="text-xl font-semibold mb-4">Medicine Stats</h3>
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

            <button
                onClick={() => setShowDetails(true)}
                className="px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded shadow"
            >
                View Details
            </button>

            {showDetails && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 backdrop-blur-sm overflow-auto p-4">
                    <div className="bg-white p-6 rounded shadow-lg max-w-4xl w-full space-y-6">
                        <h4 className="text-lg font-semibold text-center">
                            Medicine Intake Details
                        </h4>

                        <div className="flex justify-center mb-4">
                            <div style={{ width: 200, height: 200 }}>
                                <Pie data={pieData} width={200} height={200} />
                            </div>
                        </div>

                        <div className="overflow-auto max-h-96">
                            <table className="table-auto w-full border-collapse border mt-4">
                                <thead>
                                    <tr className="bg-gray-200">
                                        <th className="border px-2 py-1">Medicine</th>
                                        <th className="border px-2 py-1">Taken</th>
                                        <th className="border px-2 py-1">
                                            Missed (count & times)
                                        </th>
                                        <th className="border px-2 py-1">
                                            Taken Late (count & times)
                                        </th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {Object.entries(aggregatedCounts).map(([medName, data]) => {
                                        // Filter details by status
                                        const missedDetails = data.details.filter(d => d.status === "missed");
                                        const lateDetails = data.details.filter(d => d.status === "takenLate");

                                        return (
                                            <tr key={medName} className="text-center">
                                                <td className="border px-2 py-1">{medName}</td>
                                                <td className="border px-2 py-1">{data.taken}</td>
                                                <td className="border px-2 py-1 text-left">
                                                    {missedDetails.length}{" "}
                                                    {missedDetails.map((d, i) => (
                                                        <div key={i}>
                                                            {d.date} - {d.time}
                                                        </div>
                                                    ))}
                                                </td>
                                                <td className="border px-2 py-1 text-left">
                                                    {lateDetails.length}{" "}
                                                    {lateDetails.map((d, i) => (
                                                        <div key={i}>
                                                            {d.date} - {d.time}
                                                        </div>
                                                    ))}
                                                </td>
                                            </tr>
                                        );
                                    })}
                                </tbody>
                            </table>

                        </div>

                        <div className="flex justify-between mt-4">
                            <button
                                onClick={() => setShowDetails(false)}
                                className="px-4 py-2 bg-gray-500 hover:bg-gray-600 text-white rounded"
                            >
                                Close
                            </button>
                            <button
                                onClick={() => {
                                    const doc = new jsPDF();
                                    doc.text(`Medicine Intake Details for ${username}`, 10, 10);

                                    const tableData = Object.entries(aggregatedCounts).map(([medName, data]) => {
                                        const missedText =
                                            data.details
                                                .filter(d => d.status === "missed")
                                                .map(d => `${d.date} ${d.time}`)
                                                .join("\n") || "-";
                                        const lateText =
                                            data.details
                                                .filter(d => d.status === "takenLate")
                                                .map(d => `${d.date} ${d.time}`)
                                                .join("\n") || "-";

                                        return [
                                            medName,
                                            data.taken,
                                            `${data.details.filter(d => d.status === "missed").length}\n${missedText}`,
                                            `${data.details.filter(d => d.status === "takenLate").length}\n${lateText}`,
                                        ];
                                    });

                                    autoTable(doc, {
                                        head: [["Medicine", "Taken", "Missed (count + dates)", "Taken Late (count + dates)"]],
                                        body: tableData,
                                        startY: 20,
                                        styles: { fontSize: 10, cellPadding: 2 },
                                        headStyles: { fillColor: [156, 163, 175] },
                                    });

                                    doc.save("medicine_report.pdf");
                                }}
                                className="px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded"
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
