import React from 'react';
import { LineChart, Line, YAxis, ResponsiveContainer } from 'recharts';

interface VitalGraphProps {
  data: { timestamp: number; value: number }[];
  color: string;
}

// SaMD Note: This visualizes CoreMotion/HealthKit data streams.
// In a real device, this receives 60Hz data. Here we visualize a subset.
export const VitalGraph: React.FC<VitalGraphProps> = ({ data, color }) => {
  return (
    <div className="h-full w-full">
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={data}>
          <YAxis domain={[-2, 2]} hide />
          <Line
            type="monotone"
            dataKey="value"
            stroke={color}
            strokeWidth={2}
            dot={false}
            isAnimationActive={false} // Performance optimization for real-time data
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};