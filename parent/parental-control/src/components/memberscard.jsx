import { useNavigate } from "react-router-dom";

export default function MemberCardsGrid({ members = [] }) {
  const navigate = useNavigate();

  if (!members.length) {
    return <div className="text-center py-10 text-gray-600">No members found.</div>;
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
      {members.map((member) => (
        <div
          key={member.id}
          className="bg-white rounded-xl shadow-md border border-gray-100 p-6 hover:shadow-lg transition-shadow duration-200 cursor-pointer group"
          onClick={() => navigate(`/profile/${member.id}`)}
          tabIndex={0}
          onKeyDown={(e) => {
            if (e.key === "Enter") navigate(`/profile/${member.id}`);
          }}
        >
          <div className="flex items-center mb-4">
            <div className="bg-green-100 p-3 rounded-lg">
              <span className="text-green-700 font-bold text-lg">
                {member.username ? member.username: "NA"}
              </span>
            </div>
            <div className="ml-3">
              <div className="text-sm text-gray-500">
                age: {member.age ?? "N/A"} yrs
              </div>
            </div>
          </div>
          <div className="mb-4 flex space-x-4">
            <div>
              <div className="text-sm text-gray-700 font-medium">Missed</div>
              <div className="text-lg text-red-500 font-bold">2</div>
            </div>
            <div>
              <div className="text-sm text-gray-700 font-medium">Taken</div>
              <div className="text-lg text-green-600 font-bold">25</div>
            </div>
            <div>
              <div className="text-sm text-gray-700 font-medium">Late</div>
              <div className="text-lg text-yellow-500 font-bold">1</div>
            </div>
          </div>
          <button
            className="w-full bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200 focus:outline-none focus:ring-4 focus:ring-green-200"
            onClick={(e) => {
              e.stopPropagation();
              navigate(`/profile/${member.id}`);
            }}
          >
            View Details
          </button>
        </div>
      ))}
    </div>
  );
}
