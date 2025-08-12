import { CONFIG } from 'src/global-config';

import { LeaguesView } from 'src/sections/leagues/view';

// ----------------------------------------------------------------------

const metadata = { title: `Leagues | Dashboard - ${CONFIG.appName}` };

export default function Page() {
  return (
    <>
      <title>{metadata.title}</title>

      <LeaguesView />
    </>
  );
}
