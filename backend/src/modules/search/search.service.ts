import { Injectable } from '@nestjs/common';
import { MoviesService } from '../movies/movies.service';
import { DiningService } from '../dining/dining.service';
import { EventsService } from '../events/events.service';
import { ActivitiesService } from '../activities/activities.service';
import { ShoppingService } from '../shopping/shopping.service';
import { StaysService } from '../stays/stays.service';
import { SportsService } from '../sports/sports.service';

export interface GlobalSearchResult {
  movies: any[];
  dining: any[];
  events: any[];
  activities: any[];
  shopping: any[];
  stays: any[];
  sports: any[];
}

@Injectable()
export class SearchService {
  constructor(
    private readonly movies: MoviesService,
    private readonly dining: DiningService,
    private readonly events: EventsService,
    private readonly activities: ActivitiesService,
    private readonly shopping: ShoppingService,
    private readonly stays: StaysService,
    private readonly sports: SportsService,
  ) {}

  async searchAll(query: string): Promise<GlobalSearchResult> {
    const q = query.toLowerCase();

    const [allMovies, allDining, allEvents, allActivities, allShopping, allStays, allSports] =
      await Promise.all([
        this.movies.findAll(q),
        this.dining.findAll(),
        this.events.findAll(),
        this.activities.findAll(),
        this.shopping.findAll(),
        this.stays.findAll(),
        this.sports.findAll(),
      ]);

    return {
      movies: allMovies,
      dining: allDining.filter(
        (r) =>
          r.name.toLowerCase().includes(q) ||
          r.location.toLowerCase().includes(q) ||
          r.cuisines.some((c) => c.toLowerCase().includes(q)),
      ),
      events: allEvents.filter(
        (e) =>
          e.title.toLowerCase().includes(q) ||
          e.venue.toLowerCase().includes(q) ||
          e.category.toLowerCase().includes(q),
      ),
      activities: allActivities.filter(
        (a) =>
          a.title.toLowerCase().includes(q) ||
          a.location.toLowerCase().includes(q) ||
          a.category.toLowerCase().includes(q),
      ),
      shopping: allShopping.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          p.brand.toLowerCase().includes(q) ||
          p.category.toLowerCase().includes(q),
      ),
      stays: allStays.filter(
        (h) =>
          h.name.toLowerCase().includes(q) ||
          h.location.toLowerCase().includes(q) ||
          h.category.toLowerCase().includes(q),
      ),
      sports: allSports.filter(
        (s) =>
          s.name.toLowerCase().includes(q) ||
          s.location.toLowerCase().includes(q) ||
          s.supportedSports.some((item) => item.toLowerCase().includes(q)),
      ),
    };
  }
}
