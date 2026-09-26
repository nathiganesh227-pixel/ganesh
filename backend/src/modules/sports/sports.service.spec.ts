import { NotFoundException } from '@nestjs/common';
import { SportsService } from './sports.service';
import { SportsVenueEntity } from '../../database/entities/sports-venue.entity';
import { Repository } from 'typeorm';

describe('SportsService', () => {
  let service: SportsService;
  let mockRepo: Partial<Repository<SportsVenueEntity>>;

  const mockVenues: Partial<SportsVenueEntity>[] = [
    {
      id: 'venue_1',
      name: 'Gachibowli Multi-Sport Arena',
      supportedSports: ['Cricket', 'Football', 'Badminton'],
      location: 'Gachibowli, Hyderabad',
      startingPricePerHour: 1200,
      isPublished: true,
      rules: 'Standard turf rules apply',
    } as any,
    {
      id: 'venue_2',
      name: 'Jubilee Hills Tennis & Padel Club',
      supportedSports: ['Lawn Tennis', 'Pickleball & Padel'],
      location: 'Jubilee Hills, Hyderabad',
      startingPricePerHour: 1500,
      isPublished: true,
      rules: 'Non-marking shoes required',
    } as any,
    {
      id: 'venue_3',
      name: 'Koramangala Kickoff Turf',
      supportedSports: ['Football & Futsal'],
      location: 'Koramangala, Bangalore',
      startingPricePerHour: 1400,
      isPublished: true,
      rules: 'Football cleats allowed',
    } as any,
  ];

  beforeEach(() => {
    mockRepo = {
      find: jest.fn().mockImplementation(async ({ where }) => {
        if (where?.isPublished === true) {
          return mockVenues.filter((v) => v.isPublished === true);
        }
        return mockVenues;
      }),
      findOne: jest.fn().mockImplementation(async ({ where }) => {
        return mockVenues.find((v) => v.id === where?.id && (where?.isPublished === undefined || v.isPublished === where.isPublished)) || null;
      }),
    };

    service = new SportsService(mockRepo as Repository<SportsVenueEntity>);
  });

  it('findAll returns all published venues when no filters are applied', async () => {
    const result = await service.findAll();
    expect(result).toHaveLength(3);
    expect(mockRepo.find).toHaveBeenCalledWith({ where: { isPublished: true } });
  });

  it('findAll filters by city correctly', async () => {
    const hydResult = await service.findAll(undefined, undefined, 'Hyderabad');
    expect(hydResult).toHaveLength(2);
    expect(hydResult.map((v) => v.id)).toEqual(['venue_1', 'venue_2']);

    const blrResult = await service.findAll(undefined, undefined, 'Bangalore');
    expect(blrResult).toHaveLength(1);
    expect(blrResult[0].id).toBe('venue_3');
  });

  it('findAll filters by sport correctly', async () => {
    const tennisResult = await service.findAll('Tennis');
    expect(tennisResult).toHaveLength(1);
    expect(tennisResult[0].id).toBe('venue_2');

    const footballResult = await service.findAll('Football');
    expect(footballResult).toHaveLength(2);
  });

  it('findAll filters by search query q correctly', async () => {
    const padelSearch = await service.findAll(undefined, 'padel');
    expect(padelSearch).toHaveLength(1);
    expect(padelSearch[0].id).toBe('venue_2');

    const arenaSearch = await service.findAll(undefined, 'gachibowli');
    expect(arenaSearch).toHaveLength(1);
    expect(arenaSearch[0].id).toBe('venue_1');
  });

  it('findOne returns venue when found and published', async () => {
    const venue = await service.findOne('venue_1');
    expect(venue.id).toBe('venue_1');
    expect(venue.name).toBe('Gachibowli Multi-Sport Arena');
  });

  it('findOne throws NotFoundException when venue does not exist', async () => {
    await expect(service.findOne('non_existent')).rejects.toThrow(NotFoundException);
  });
});
