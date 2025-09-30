
import { useState, useEffect } from "react";
import { Line } from "react-chartjs-2";
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import { format } from "date-fns";
import { supabase } from "../supabase/supabase-client";

// Helper function to safely format a date string
const safeFormatDate = (dateString, formatString = 'MMM dd, yyyy') => {
    if (!dateString) return 'N/A Date';
    const date = new Date(dateString);
    if (isNaN(date.getTime())) return 'Invalid Date';
    return format(date, formatString);
};

// Helper to extract Systolic pressure (the first number in "120/80")
const getSystolic = (bpString) => {
    if (!bpString) return 0;
    const parts = String(bpString).split('/');
    return parseFloat(parts[0]) || 0;
};


export default function HealthReports({ childId, username }) {
    const [loading, setLoading] = useState(true);
    const [showDetails, setShowDetails] = useState(false);
    const [allReports, setAllReports] = useState([]);
    const [lastReport, setLastReport] = useState({});
    const [chartData, setChartData] = useState({});

    useEffect(() => {
        async function fetchHealthReports() {
            setLoading(true);

            // Fetch all reports, ordered descending by report_date
            const { data, error } = await supabase
                .from("health_reports")
                .select("*")
                .eq("child_id", childId)
                .order("report_date", { ascending: false }) // Initial fetch is descending
                .limit(20);

            if (error) {
                console.error("Error fetching health reports:", error);
                setLoading(false);
                return;
            }

            const validReports = data.filter(r => r.report_date && !isNaN(new Date(r.report_date)));

            // 1. Sort Ascending: Required for chart (Left -> Right trend)
            const sortedReportsAsc = validReports.sort((a, b) => new Date(b.report_date) - new Date(a.report_date));

            // 2. Set All Reports: Sorted Descending for the Modal Table view (Newest first)
            setAllReports(validReports);

            // 3. Get Most Recent Report: Last element of the Ascending array is the latest.
            const mostRecent = sortedReportsAsc[sortedReportsAsc.length - 1] || {
                blood_pressure: 'N/A',
                cholesterol: 'N/A',
                blood_sugar: 'N/A',
            };

            // FIX: Use the actual snake_case column names from the fetched object
            setLastReport({
                bloodPressure: mostRecent.bloodPressure || 'N/A',
                cholesterol: mostRecent.cholesterol || 'N/A',
                bloodSugar: mostRecent.bloodSugar || 'N/A',
            });

            // 4. Prepare Chart Data: Use the Ascending array for correct chart axis order
            const recentReportsForChart = sortedReportsAsc.slice(-5);

            setChartData({
                labels: recentReportsForChart.map(r => safeFormatDate(r.report_date, 'MMM dd')),
                datasets: [
                    {
                        label: 'Blood Sugar (mg/dL)',
                        data: recentReportsForChart.map(r => parseFloat(r.bloodSugar) || 0),
                        borderColor: 'rgb(243, 46, 144)',
                        backgroundColor: 'rgba(236, 72, 153, 0.1)',
                        yAxisID: 'y-blood-sugar',
                        tension: 0.3,
                        pointRadius: 5,
                    },
                    {
                        label: 'Systolic BP (mmHg)',
                        data: recentReportsForChart.map(r => getSystolic(r.bloodPressure)),
                        borderColor: 'rgb(0, 134, 29)',
                        backgroundColor: 'rgba(0, 138, 30, 0.1)',
                        yAxisID: 'y-blood-sugar',
                        tension: 0.3,
                        pointRadius: 5,
                    },
                    {
                        label: 'Cholesterol (mg/dL)',
                        data: recentReportsForChart.map(r => parseFloat(r.cholesterol) || 0),
                        borderColor: 'rgb(79, 0, 214)',
                        backgroundColor: 'rgba(124, 58, 237, 0.1)',
                        yAxisID: 'y-cholesterol',
                        tension: 0.3,
                        fill: false,
                        pointRadius: 5,
                    },
                ],
            });

            setLoading(false);
        }

        fetchHealthReports();
    }, [childId]);


    // --- START RENDERING LOGIC ---
    if (loading) {
        return (
            <section className="bg-white shadow rounded p-6">
                <div>Loading health reports...</div>
            </section>
        );
    }

    if (allReports.length === 0) {
        return (
            <section className="bg-white shadow rounded p-6">
                <h3 className="text-xl font-semibold mb-4">Health Reports</h3>
                <div className="text-center py-10 text-gray-500">
                    No health report history found for this child.
                </div>
            </section>
        );
    }
    // --- END RENDERING LOGIC ---

    // Chart options for the summary graph (Multi-Axis Configuration)
    const chartOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: true,
                position: 'top',
            },
            title: {
                display: true,
                text: `Key Health Metrics Trend (Last ${Math.min(5, allReports.length)} Records)`,
            },
            tooltip: {
                mode: 'index',
                intersect: false,
            }
        },
        scales: {
            x: {
                grid: {
                    display: false
                }
            },
            'y-blood-sugar': {
                type: 'linear',
                display: true,
                position: 'left',
                title: {
                    display: true,
                    text: 'BP / Blood Sugar',
                    color: 'rgb(236, 72, 153)',
                },
                beginAtZero: false,
            },
            'y-cholesterol': {
                type: 'linear',
                display: true,
                position: 'right',
                title: {
                    display: true,
                    text: 'Cholesterol (mg/dL)',
                    color: 'rgb(124, 58, 237)',
                },
                grid: {
                    drawOnChartArea: false,
                },
                beginAtZero: false,
            },
        }
    };

    // Handler to export the full table to PDF
    const exportHealthReportPDF = () => {
        const doc = new jsPDF();
        doc.text(`Full Health Reports for ${username}`, 10, 10);

        // FIX: Use snake_case column names from the report object
        const tableData = allReports.map((report) => [
            safeFormatDate(report.report_date, 'yyyy-MM-dd'),
            report.bloodPressure || 'N/A',
            report.bloodSugar || 'N/A',
            report.cholesterol || 'N/A',
        ]);

        autoTable(doc, {
            head: [['Date', 'Blood Pressure (mmHg)', 'Blood Sugar (mg/dL)', 'Cholesterol (mg/dL)']],
            body: tableData,
            startY: 20,
            styles: { fontSize: 8, cellPadding: 2 },
            headStyles: { fillColor: [59, 130, 246] },
        });

        doc.save(`health_reports_${username}.pdf`);
    };

    return (
        <section className="bg-white shadow rounded p-6">
            <h3 className="text-xl font-semibold mb-4">Health Reports</h3>

            {/* 1. Summary Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
                <div className="bg-blue-50 p-4 rounded shadow text-center">
                    <div className="font-bold text-blue-600 text-lg">{lastReport.bloodPressure} mmHg</div>
                    <div className="text-gray-700">Latest Blood Pressure</div>
                </div>
                <div className="bg-pink-50 p-4 rounded shadow text-center">
                    <div className="font-bold text-pink-600 text-lg">{lastReport.bloodSugar} mg/dL</div>
                    <div className="text-gray-700">Latest Blood Sugar</div>
                </div>
                <div className="bg-purple-50 p-4 rounded shadow text-center">
                    <div className="font-bold text-purple-600 text-lg">{lastReport.cholesterol} mg/dL</div>
                    <div className="text-gray-700">Latest Cholesterol</div>
                </div>
            </div>

            {/* 2. Variation Graph (Multi-Line, Dual-Axis) */}
            <div className="h-96 mb-6 p-4 border rounded-lg">
                {allReports.length > 1 ? (
                    <Line data={chartData} options={chartOptions} />
                ) : (
                    <div className="text-center py-20 text-gray-500">
                        Need at least two valid data points to show a trend graph.
                    </div>
                )}
            </div>

            {/* 3. Detail Button */}
            <div className="text-center">
                <button
                    onClick={() => setShowDetails(true)}
                    className="px-6 py-2 bg-green-600 hover:bg-blue-700 text-white font-medium rounded-lg shadow-lg transition duration-150"
                >
                    View Full History
                </button>
            </div>


            {/* 4. Full Details Modal */}
            {showDetails && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm overflow-auto p-4">
                    <div className="bg-white p-6 rounded-lg shadow-2xl max-w-5xl w-full space-y-4">
                        <h4 className="text-xl font-semibold text-center text-blue-600">
                            Complete Health Report History for {username}
                        </h4>

                        <div className="overflow-y-auto max-h-[70vh] border rounded">
                            <table className="min-w-full table-auto border-collapse">
                                <thead>
                                    <tr className="bg-gray-100 text-gray-600 text-sm leading-normal">
                                        <th className="py-3 px-6 text-left sticky top-0 bg-gray-100">Date</th>
                                        <th className="py-3 px-6 text-left sticky top-0 bg-gray-100">Blood Pressure (mmHg)</th>
                                        <th className="py-3 px-6 text-left sticky top-0 bg-gray-100">Blood Sugar (mg/dL)</th>
                                        <th className="py-3 px-6 text-left sticky top-0 bg-gray-100">Cholesterol (mg/dL)</th>
                                    </tr>
                                </thead>
                                <tbody className="text-gray-600 text-sm font-light">
                                    {allReports.map((report, index) => (
                                        <tr key={index} className="border-b border-gray-200 hover:bg-gray-50">
                                            <td className="py-3 px-6 text-left whitespace-nowrap">
                                                {safeFormatDate(report.report_date)}
                                            </td>
                                            {/* FIX: Use snake_case column names */}
                                            <td className="py-3 px-6 text-left">{report.bloodPressure || 'N/A'}</td>
                                            <td className="py-3 px-6 text-left">{report.bloodSugar || 'N/A'}</td>
                                            <td className="py-3 px-6 text-left">{report.cholesterol || 'N/A'}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>

                        <div className="flex justify-end space-x-3 mt-4">
                            <button
                                onClick={exportHealthReportPDF}
                                className="px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded shadow-md"
                            >
                                Export PDF
                            </button>
                            <button
                                onClick={() => setShowDetails(false)}
                                className="px-4 py-2 bg-gray-500 hover:bg-gray-600 text-white rounded shadow-md"
                            >
                                Close
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </section>
    );
}