import { atom } from "jotai";

// Mirrors the PX4 SITL home in docker/.env (PX4_HOME_LAT/LON/ALT). We will load from the backend once that exists.
export const INITIAL_VIEW = {
	lat: 34.288889,
	lon: -117.646667,
	altMSL: 226.0,
};

export const VIEW_HEIGHT_M = 4000;

export type FleetConfig = {
	id: string;
	vehicleIds: number[];
	name: string;
	color: string;
};

const vanguard: FleetConfig = {
	id: "vanguard",
	vehicleIds: [1],
	name: "Vanguard",
	color: "#28d4e1"
};

const reaper: FleetConfig = {
	id: "reaper",
	vehicleIds: [2],
	name: "Reaper",
	color: "#f5a623"
};
export const fleetConfigAtom = atom<FleetConfig[]>([vanguard, reaper]);
